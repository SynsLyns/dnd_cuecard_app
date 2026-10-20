import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/player_shared_card.dart';
import '../models/player_initiative.dart';

class PlayerAppState extends ChangeNotifier {
  static const _campaignIdKey = 'player_campaign_id';
  static const _campaignNameKey = 'player_campaign_name';
  static const _displayNameKey = 'player_display_name';
  static const _userIdKey = 'player_user_id';

  final SupabaseClient? _client;
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String? campaignId;
  String? campaignName;
  String? displayName;
  List<PlayerSharedCard> cards = [];
  PlayerInitiativeEncounter? initiativeEncounter;
  Map<String, int> lastViewedVersions = {};
  bool isLoading = false;
  String? error;
  RealtimeChannel? _channel;
  bool _isDisposed = false;

  PlayerAppState(this._client);

  Future<void> initialize(String? joinCode) async {
    if (_client == null) return;
    isLoading = true;
    notifyListeners();
    try {
      final savedCampaignId = await _preferences.getString(_campaignIdKey);
      final savedCampaignName = await _preferences.getString(_campaignNameKey);
      final savedDisplayName = await _preferences.getString(_displayNameKey);
      final currentUser = _client.auth.currentUser;
      final savedUserId = await _preferences.getString(_userIdKey);

      if (currentUser != null &&
          savedUserId != null &&
          savedUserId != currentUser.id) {
        await _clearSavedCampaign();
      }

      if (joinCode != null && joinCode.trim().isNotEmpty) {
        if (currentUser != null &&
            savedUserId == currentUser.id &&
            savedDisplayName != null) {
          await _joinCampaign(joinCode, savedDisplayName);
          await _loadLastViewedVersions();
          await _loadCards();
          await _loadInitiative();
          _subscribeToCards();
        }
      } else if (currentUser != null &&
          savedUserId == currentUser.id &&
          savedCampaignId != null &&
          savedCampaignName != null &&
          savedDisplayName != null) {
        campaignId = savedCampaignId;
        campaignName = savedCampaignName;
        displayName = savedDisplayName;
        await _loadLastViewedVersions();
        await _loadCards();
        await _loadInitiative();
        _subscribeToCards();
      }
    } catch (exception) {
      error = _friendlyError(exception);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> join(String code, String name) async {
    if (_client == null) {
      error = 'Player sharing is not configured.';
      notifyListeners();
      return;
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      if (_client.auth.currentUser == null) {
        throw const AuthException('Sign in before joining a campaign.');
      }
      await _joinCampaign(code, name);
      await _loadLastViewedVersions();
      await _loadCards();
      await _loadInitiative();
      _subscribeToCards();
    } catch (exception) {
      error = _friendlyError(exception);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _joinCampaign(String code, String name) async {
    final response = await _client!.rpc(
      'join_campaign',
      params: {'code': code.trim(), 'display_name': name.trim()},
    );
    if (response is! List || response.isEmpty || response.first is! Map) {
      throw const FormatException(
        'The server returned an invalid join response.',
      );
    }
    final campaign = Map<String, dynamic>.from(response.first as Map);
    final joinedCampaignId = campaign['campaign_id']?.toString();
    final joinedCampaignName = campaign['campaign_name']?.toString();
    if (joinedCampaignId == null ||
        joinedCampaignId.isEmpty ||
        joinedCampaignName == null ||
        joinedCampaignName.isEmpty) {
      throw const FormatException(
        'The server returned incomplete campaign details.',
      );
    }

    await _removeSubscription();
    campaignId = joinedCampaignId;
    campaignName = joinedCampaignName;
    displayName = name.trim();
    await _preferences.setString(_campaignIdKey, joinedCampaignId);
    await _preferences.setString(_campaignNameKey, joinedCampaignName);
    await _preferences.setString(_displayNameKey, name.trim());
    await _preferences.setString(_userIdKey, _client.auth.currentUser!.id);
  }

  Future<void> _loadCards() async {
    final id = campaignId;
    if (id == null) return;
    final response = await _client!
        .from('shared_cards')
        .select(
          'id, payload, schema_version, version, revoked, updated_at, shared_at',
        )
        .eq('campaign_id', id)
        .eq('revoked', false)
        .order('updated_at', ascending: false);
    final loadedCards = (response as List<dynamic>)
        .map(
          (row) =>
              PlayerSharedCard.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    cards = await Future.wait(
      loadedCards.map((card) async {
        final iconPath = card.payload['icon_path'];
        if (iconPath is! String || iconPath.isEmpty) return card;
        try {
          final iconBytes = await _client.storage
              .from('shared-card-icons')
              .download(iconPath);
          return PlayerSharedCard(
            id: card.id,
            version: card.version,
            schemaVersion: card.schemaVersion,
            payload: card.payload,
            iconBytes: iconBytes,
          );
        } catch (exception) {
          error = _friendlyError(exception);
          return card;
        }
      }),
    );
    if (!_isDisposed) notifyListeners();
  }

  Future<void> _loadInitiative() async {
    final id = campaignId;
    if (id == null) {
      initiativeEncounter = null;
      return;
    }
    final row = await _client!
        .from('initiative_encounters')
        .select('player_state')
        .eq('campaign_id', id)
        .eq('active', true)
        .maybeSingle();
    if (row == null) {
      initiativeEncounter = null;
      return;
    }
    final playerState = row['player_state'];
    if (playerState is! Map) {
      throw const FormatException('Invalid shared initiative state.');
    }
    initiativeEncounter = PlayerInitiativeEncounter.fromJson(
      Map<String, dynamic>.from(playerState),
    );
  }

  void _subscribeToCards() {
    final id = campaignId;
    if (id == null) return;
    unawaited(_removeSubscription());
    _channel = _client!
        .channel('player-shared-cards-$id')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shared_cards',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'campaign_id',
            value: id,
          ),
          callback: (_) => unawaited(_refreshCardsFromRealtime()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'card_share_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'campaign_id',
            value: id,
          ),
          callback: (_) => unawaited(_refreshCardsFromRealtime()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'initiative_encounters',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'campaign_id',
            value: id,
          ),
          callback: (_) => unawaited(_refreshInitiativeFromRealtime()),
        )
        .subscribe();
  }

  Future<void> _refreshInitiativeFromRealtime() async {
    try {
      await _loadInitiative();
    } catch (exception) {
      error = _friendlyError(exception);
    }
    if (!_isDisposed) notifyListeners();
  }

  Future<void> _refreshCardsFromRealtime() async {
    try {
      await _loadCards();
      error = null;
    } catch (exception) {
      error = _friendlyError(exception);
    }
    if (!_isDisposed) notifyListeners();
  }

  Future<void> markViewed(PlayerSharedCard card) async {
    final key = _viewedVersionKey(card.id);
    await _preferences.setInt(key, card.version);
    lastViewedVersions[card.id] = card.version;
    notifyListeners();
  }

  bool hasUnseenUpdate(PlayerSharedCard card) =>
      card.version > (lastViewedVersions[card.id] ?? 0);

  Future<void> leaveCampaign() async {
    await _removeSubscription();
    campaignId = null;
    campaignName = null;
    displayName = null;
    cards = [];
    initiativeEncounter = null;
    lastViewedVersions = {};
    await _clearSavedCampaign();
    notifyListeners();
  }

  Future<void> handleSignedOut() async {
    await _removeSubscription();
    campaignId = null;
    campaignName = null;
    displayName = null;
    cards = [];
    initiativeEncounter = null;
    lastViewedVersions = {};
    await _clearSavedCampaign();
    notifyListeners();
  }

  Future<void> _clearSavedCampaign() async {
    await _preferences.remove(_campaignIdKey);
    await _preferences.remove(_campaignNameKey);
    await _preferences.remove(_displayNameKey);
    await _preferences.remove(_userIdKey);
  }

  Future<void> signOut() async {
    await _removeSubscription();
    await _client?.auth.signOut();
    campaignId = null;
    campaignName = null;
    displayName = null;
    cards = [];
    initiativeEncounter = null;
    lastViewedVersions = {};
    await _clearSavedCampaign();
    notifyListeners();
  }

  Future<void> retry() async {
    error = null;
    isLoading = true;
    notifyListeners();
    try {
      if (campaignId == null) {
        await initialize(null);
      } else {
        await _loadCards();
        await _loadInitiative();
        _subscribeToCards();
      }
    } catch (exception) {
      error = _friendlyError(exception);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLastViewedVersions() async {
    final id = campaignId;
    if (id == null) return;
    final keys = await _preferences.getKeys();
    final prefix = 'player_last_viewed_${id}_';
    lastViewedVersions = {
      for (final key in keys.where((key) => key.startsWith(prefix)))
        key.substring(prefix.length): await _preferences.getInt(key) ?? 0,
    };
  }

  String _viewedVersionKey(String cardId) =>
      'player_last_viewed_${campaignId}_$cardId';

  Future<void> _removeSubscription() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      await _client?.removeChannel(channel);
    }
  }

  String _friendlyError(Object exception) {
    final detail = exception.toString();
    return 'Sharing service error: $detail. Check your connection. If the '
        'service is unavailable, the DM may need to restore a paused Supabase '
        'project from the dashboard.';
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_removeSubscription());
    super.dispose();
  }
}
