import 'package:dnd_cuecard_app/logic/cue_card_database.dart';
import 'package:dnd_cuecard_app/logic/supabase_service.dart';
import 'package:dnd_cuecard_app/models/campaign.dart';
import 'package:dnd_cuecard_app/models/card_share.dart';
import 'package:dnd_cuecard_app/models/card_type.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/models/rarity.dart';
import 'package:dnd_cuecard_app/models/relationship.dart';
import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:flutter/material.dart';

enum CardShareStatus { notShared, upToDate, changesNotPushed }

class CardShareFailure {
  final String cardTitle;
  final String message;

  const CardShareFailure(this.cardTitle, this.message);
}

class CardShareBatchResult {
  final int succeededCount;
  final List<CardShareFailure> failures;

  const CardShareBatchResult({
    required this.succeededCount,
    required this.failures,
  });
}

class AppState extends ChangeNotifier {
  static final CueCardDatabase _cueCardDatabase = CueCardDatabase();
  static final SupabaseService _supabaseService = SupabaseService();

  List<CueCard> cueCards = [];
  List<Rarity> rarities = [];
  List<CardType> cardTypes = [];
  List<Tag> tags = [];
  List<Relationship> relationships = [];

  // Card Sharing State
  Map<String, CardShare> cardShares = {};
  List<Campaign> campaigns = [];
  String? activeCampaignId;

  CueCard? selectedCard;

  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCueCardCount = 0;

  String searchText = '';
  List<Tag> searchSelectedTags = [];

  bool _isRelationshipMode = false;
  bool get isRelationshipMode => _isRelationshipMode;
  set isRelationshipMode(bool value) {
    _isRelationshipMode = value;
    notifyListeners();
  }

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCueCardCount => _totalCueCardCount;
  int get totalPages => (_totalCueCardCount / _pageSize).ceil();

  Campaign? get activeCampaign {
    if (activeCampaignId == null) return null;
    return campaigns.where((c) => c.id == activeCampaignId).firstOrNull;
  }

  AppState();

  Future<void> init() async {
    await Future.wait([
      loadRarities(),
      loadCardTypes(),
      loadCueCards(),
      loadTags(),
      loadRelationships(),
      loadCardShares(),
      loadCampaigns(),
    ]);
  }

  Future<void> loadRarities() async {
    rarities = await _cueCardDatabase.getRarities();
    notifyListeners();
  }

  Future<void> loadCardTypes() async {
    cardTypes = await _cueCardDatabase.getCardTypes();
    notifyListeners();
  }

  Future<void> loadCueCards({int? page, int? size}) async {
    if (page != null) _currentPage = page;
    if (size != null) _pageSize = size;

    final offset = (_currentPage - 1) * _pageSize;
    cueCards = await _cueCardDatabase.getPaginatedCueCards(
      searchSelectedTags,
      searchText,
      _pageSize,
      offset,
    );
    _totalCueCardCount = await _cueCardDatabase.getTotalCueCardCount(
      searchSelectedTags,
      searchText,
    );
    notifyListeners();
  }

  Future<void> loadTags() async {
    tags = await _cueCardDatabase.getTags();
    notifyListeners();
  }

  Future<void> loadRelationships() async {
    relationships = await _cueCardDatabase.getAllRelationships();
    notifyListeners();
  }

  Future<void> loadCardShares() async {
    try {
      final shares = await _cueCardDatabase.getAllCardShares();
      cardShares = {for (final s in shares) '${s.cardUuid}_${s.campaignId}': s};
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadCampaigns() async {
    try {
      if (_supabaseService.currentUser != null) {
        campaigns = await _supabaseService.fetchDmCampaigns();
        if (activeCampaignId == null && campaigns.isNotEmpty) {
          activeCampaignId = campaigns.first.id;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void setActiveCampaign(String? campaignId) {
    activeCampaignId = campaignId;
    notifyListeners();
  }

  /// Evaluates whether a card is not shared, up to date, or has changes not pushed
  CardShareStatus getCardShareStatus(CueCard card, {String? campaignId}) {
    final targetCampaignId = campaignId ?? activeCampaignId;
    if (targetCampaignId == null || card.uuid == null) {
      return CardShareStatus.notShared;
    }
    final key = '${card.uuid}_$targetCampaignId';
    final share = cardShares[key];
    if (share == null) {
      return CardShareStatus.notShared;
    }

    final typeName = cardTypes
        .where((t) => t.id == card.type)
        .firstOrNull
        ?.name;
    final typeColor = cardTypes
        .where((t) => t.id == card.type)
        .firstOrNull
        ?.color
        .toARGB32();
    final rarityName = rarities
        .where((r) => r.id == card.rarity)
        .firstOrNull
        ?.name;
    final rarityColor = rarities
        .where((r) => r.id == card.rarity)
        .firstOrNull
        ?.color
        .toARGB32();

    final currentHash = card.canonicalHash(
      typeName: typeName,
      typeColor: typeColor,
      rarityName: rarityName,
      rarityColor: rarityColor,
    );

    if (currentHash == share.pushedHash) {
      return CardShareStatus.upToDate;
    } else {
      return CardShareStatus.changesNotPushed;
    }
  }

  Future<void> shareCard(CueCard card, [String? targetCampaignId]) async {
    final campaignId = targetCampaignId ?? activeCampaignId;
    if (campaignId == null) {
      throw CloudSharingException('No campaign selected.');
    }
    final typeName = cardTypes
        .where((t) => t.id == card.type)
        .firstOrNull
        ?.name;
    final typeColor = cardTypes
        .where((t) => t.id == card.type)
        .firstOrNull
        ?.color
        .toARGB32();
    final rarityName = rarities
        .where((r) => r.id == card.rarity)
        .firstOrNull
        ?.name;
    final rarityColor = rarities
        .where((r) => r.id == card.rarity)
        .firstOrNull
        ?.color
        .toARGB32();

    final share = await _supabaseService.shareOrPushCard(
      campaignId: campaignId,
      card: card,
      typeName: typeName,
      typeColor: typeColor,
      rarityName: rarityName,
      rarityColor: rarityColor,
    );
    cardShares['${card.uuid}_$campaignId'] = share;
    notifyListeners();
  }

  Future<void> pushCardUpdate(CueCard card, [String? targetCampaignId]) async {
    await shareCard(card, targetCampaignId);
  }

  Future<List<CueCard>> getCardsByIds(Set<int> ids) async {
    if (ids.isEmpty) return [];
    final cards = await _cueCardDatabase.getAllCueCards();
    return cards
        .where((card) => card.id != null && ids.contains(card.id))
        .toList();
  }

  Future<CardShareBatchResult> shareCards(
    Iterable<CueCard> cards, [
    String? targetCampaignId,
  ]) async {
    final campaignId = targetCampaignId ?? activeCampaignId;
    if (campaignId == null) {
      throw CloudSharingException('No campaign selected.');
    }

    var succeededCount = 0;
    final failures = <CardShareFailure>[];
    for (final card in cards) {
      try {
        await shareCard(card, campaignId);
        succeededCount++;
      } catch (error) {
        failures.add(
          CardShareFailure(card.title ?? 'Untitled', error.toString()),
        );
      }
    }
    return CardShareBatchResult(
      succeededCount: succeededCount,
      failures: failures,
    );
  }

  Future<void> unshareCard(CueCard card, [String? targetCampaignId]) async {
    final campaignId = targetCampaignId ?? activeCampaignId;
    if (campaignId == null || card.uuid == null) return;

    await _supabaseService.unshareCard(
      campaignId: campaignId,
      cardUuid: card.uuid!,
    );
    cardShares.remove('${card.uuid}_$campaignId');
    notifyListeners();
  }

  Future<CardShareBatchResult> pushAllOutdatedCards([
    String? targetCampaignId,
  ]) async {
    final campaignId = targetCampaignId ?? activeCampaignId;
    if (campaignId == null) {
      throw CloudSharingException('No campaign selected.');
    }

    final allCards = await _cueCardDatabase.getAllCueCards();
    final outdatedCards = allCards.where(
      (card) =>
          getCardShareStatus(card, campaignId: campaignId) ==
          CardShareStatus.changesNotPushed,
    );
    return shareCards(outdatedCards, campaignId);
  }

  void selectCard(CueCard? card) {
    selectedCard = card;
    notifyListeners();
  }

  Future<void> removeCueCard(int id) async {
    final cardToDelete = cueCards.where((c) => c.id == id).firstOrNull;
    if (cardToDelete?.uuid != null) {
      await _cueCardDatabase.deleteCardSharesForCard(cardToDelete!.uuid!);
      cardShares.removeWhere((k, _) => k.startsWith('${cardToDelete.uuid}_'));
    }

    await _cueCardDatabase.deleteCueCard(id);

    await loadCueCards(page: _currentPage, size: _pageSize);
    await loadRelationships();
    if (selectedCard != null && selectedCard!.id == id) {
      selectedCard = null;
    }
    notifyListeners();
  }

  void goToPage(int page) {
    if (page > 0 && page <= totalPages) {
      _currentPage = page;
      loadCueCards(page: _currentPage);
    }
  }

  void setItemsPerPage(int size) {
    if (_pageSize == size) return;
    _pageSize = size;
    _currentPage = 1;
    loadCueCards(page: _currentPage, size: _pageSize);
  }

  void updateFilteredCueCards({List<Tag>? tags, String? text}) {
    if (tags != null) searchSelectedTags = tags;
    if (text != null) searchText = text;
    _currentPage = 1;
    loadCueCards(page: _currentPage, size: _pageSize);
  }
}
