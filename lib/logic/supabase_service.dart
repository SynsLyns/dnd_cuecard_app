import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/campaign.dart';
import '../models/card_share.dart';
import '../models/cue_card.dart';
import 'cue_card_database.dart';
import 'join_code_generator.dart';

class CloudSharingException implements Exception {
  final String message;
  final dynamic cause;
  CloudSharingException(this.message, [this.cause]);

  static String userMessage(Object error) {
    return '$error Check your connection and Supabase project status; free '
        'projects may pause after inactivity and can be resumed in the dashboard.';
  }

  @override
  String toString() => message;
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final CueCardDatabase _database = CueCardDatabase();

  bool get isConfigured => SupabaseConfig.isConfigured;

  bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient? get client {
    if (!isInitialized) return null;
    return Supabase.instance.client;
  }

  User? get currentUser => client?.auth.currentUser;

  Stream<AuthState>? get authStateChanges => client?.auth.onAuthStateChange;

  /// Initializes Supabase client if not already initialized.
  Future<bool> initializeClient([
    String? customUrl,
    String? customAnonKey,
  ]) async {
    final url = customUrl ?? SupabaseConfig.url;
    final anonKey = customAnonKey ?? SupabaseConfig.anonKey;

    if (url.trim().isEmpty || anonKey.trim().isEmpty) {
      return false;
    }

    if (isInitialized) {
      return true;
    }

    try {
      await Supabase.initialize(url: url, publishableKey: anonKey);
      return true;
    } catch (e) {
      // In tests or offline, don't crash the desktop app
      return false;
    }
  }

  // --- Auth Methods ---

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final cl = _requireClient();
    try {
      return await cl.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      throw CloudSharingException('Sign-in failed: ${e.toString()}', e);
    }
  }

  Future<void> signInWithOtp({required String email}) async {
    final cl = _requireClient();
    try {
      await cl.auth.signInWithOtp(email: email.trim());
    } catch (e) {
      throw CloudSharingException(
        'Failed to send email OTP: ${e.toString()}',
        e,
      );
    }
  }

  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    final cl = _requireClient();
    try {
      return await cl.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.magiclink,
      );
    } catch (e) {
      throw CloudSharingException(
        'OTP verification failed: ${e.toString()}',
        e,
      );
    }
  }

  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    final cl = _requireClient();
    try {
      return await cl.auth.signUp(email: email.trim(), password: password);
    } catch (e) {
      throw CloudSharingException('Sign-up failed: ${e.toString()}', e);
    }
  }

  Future<void> signOut() async {
    final cl = client;
    if (cl != null) {
      await cl.auth.signOut();
    }
  }

  // --- Campaign Methods ---

  Future<List<Campaign>> fetchDmCampaigns() async {
    final cl = _requireClient();
    final user = currentUser;
    if (user == null) return [];

    try {
      final response = await cl
          .from('campaigns')
          .select()
          .eq('dm_id', user.id)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((item) => Campaign.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CloudSharingException(
        'Failed to fetch campaigns: ${e.toString()}',
        e,
      );
    }
  }

  Future<Campaign> createCampaign(String name) async {
    final cl = _requireClient();
    final user = currentUser;
    if (user == null) {
      throw CloudSharingException(
        'You must be signed in to create a campaign.',
      );
    }

    try {
      final joinCode = await JoinCodeGenerator.generateUnique((
        candidate,
      ) async {
        final existing = await cl
            .from('campaigns')
            .select('id')
            .eq('join_code', candidate)
            .maybeSingle();
        return existing != null;
      });

      final insertData = {
        'dm_id': user.id,
        'name': name.trim(),
        'join_code': joinCode,
      };

      final response = await cl
          .from('campaigns')
          .insert(insertData)
          .select()
          .single();
      return Campaign.fromMap(response);
    } catch (e) {
      throw CloudSharingException(
        'Failed to create campaign: ${e.toString()}',
        e,
      );
    }
  }

  Future<void> deleteCampaign(String campaignId) async {
    final cl = _requireClient();
    try {
      await cl.from('campaigns').delete().eq('id', campaignId);
    } catch (e) {
      throw CloudSharingException(
        'Failed to delete campaign: ${e.toString()}',
        e,
      );
    }
  }

  // --- Card Sharing Methods ---

  /// Shares or updates a card in a campaign.
  /// If already shared, updates the existing row's payload, increments `version`, and sets `updated_at`.
  /// Updates the local `card_shares` table with the latest cloud state and pushed hash.
  Future<CardShare> shareOrPushCard({
    required String campaignId,
    required CueCard card,
    String? typeName,
    int? typeColor,
    String? rarityName,
    int? rarityColor,
  }) async {
    final cl = _requireClient();
    final cardUuid = card.uuid;
    if (cardUuid == null || cardUuid.isEmpty) {
      throw CloudSharingException('Card does not have a valid UUID.');
    }

    final payload = card.toSharedPayload(
      typeName: typeName,
      typeColor: typeColor,
      rarityName: rarityName,
      rarityColor: rarityColor,
    );
    final canonicalHash = card.canonicalHash(
      typeName: typeName,
      typeColor: typeColor,
      rarityName: rarityName,
      rarityColor: rarityColor,
    );

    try {
      // Check if row already exists in shared_cards for this campaign & card
      final existing = await cl
          .from('shared_cards')
          .select('id, version')
          .eq('campaign_id', campaignId)
          .eq('source_card_uuid', cardUuid)
          .maybeSingle();

      String sharedCardId;
      int pushedVersion;
      final now = DateTime.now().toUtc();

      if (existing != null) {
        // Update existing row
        sharedCardId = existing['id'] as String;
        final currentVersion = existing['version'] as int;
        pushedVersion = currentVersion + 1;

        final updated = await cl
            .from('shared_cards')
            .update({
              'payload': payload,
              'version': pushedVersion,
              'revoked': false,
              'updated_at': now.toIso8601String(),
            })
            .eq('id', sharedCardId)
            .select('id')
            .maybeSingle();
        if (updated == null) {
          throw CloudSharingException(
            'The shared card could not be updated. Check your campaign permissions.',
          );
        }
      } else {
        // Insert new row
        pushedVersion = 1;
        final inserted = await cl
            .from('shared_cards')
            .insert({
              'campaign_id': campaignId,
              'source_card_uuid': cardUuid,
              'payload': payload,
              'schema_version': 1,
              'version': pushedVersion,
              'revoked': false,
              'shared_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            })
            .select('id')
            .single();

        sharedCardId = inserted['id'] as String;
      }

      // Record in local card_shares SQLite table
      final shareRecord = CardShare(
        cardUuid: cardUuid,
        campaignId: campaignId,
        sharedCardId: sharedCardId,
        pushedVersion: pushedVersion,
        pushedHash: canonicalHash,
        pushedAt: now,
      );

      await _database.insertOrUpdateCardShare(shareRecord);
      return shareRecord;
    } catch (e) {
      throw CloudSharingException('Failed to share card: ${e.toString()}', e);
    }
  }

  /// Soft-deletes a shared card by marking revoked = true in Supabase.
  Future<void> unshareCard({
    required String campaignId,
    required String cardUuid,
  }) async {
    final cl = _requireClient();
    try {
      final updated = await cl
          .from('shared_cards')
          .update({
            'revoked': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('campaign_id', campaignId)
          .eq('source_card_uuid', cardUuid)
          .select('id')
          .maybeSingle();
      if (updated == null) {
        throw CloudSharingException(
          'The shared card could not be unshared. Check your campaign permissions.',
        );
      }

      // Remove local share record so badge switches to "Not shared"
      await _database.deleteCardShare(cardUuid, campaignId);
    } catch (e) {
      throw CloudSharingException('Failed to unshare card: ${e.toString()}', e);
    }
  }

  SupabaseClient _requireClient() {
    final cl = client;
    if (cl == null) {
      throw CloudSharingException(
        'Supabase is not configured or initialized. Please configure credentials in Settings.',
      );
    }
    return cl;
  }
}
