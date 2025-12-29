import 'package:dnd_cuecard_app/logic/cue_card_database.dart';
import 'package:dnd_cuecard_app/models/card_type.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/models/rarity.dart';
import 'package:dnd_cuecard_app/models/relationship.dart';
import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  static final CueCardDatabase _cueCardDatabase = CueCardDatabase();

  List<CueCard> cueCards = [];
  List<Rarity> rarities = [];
  List<CardType> cardTypes = [];
  List<Tag> tags = [];
  List<Relationship> relationships = [];

  CueCard? selectedCard;

  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCueCardCount = 0;

  String searchText = '';
  List<Tag> searchSelectedTags = [];

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCueCardCount => _totalCueCardCount;
  int get totalPages => (_totalCueCardCount / _pageSize).ceil();

  AppState();

  Future<void> init() async {
    await Future.wait([
      loadRarities(),
      loadCardTypes(),
      loadCueCards(),
      loadTags(),
      loadRelationships(),
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
    cueCards = await _cueCardDatabase.getPaginatedCueCards(searchSelectedTags, searchText, _pageSize, offset);
    _totalCueCardCount = await _cueCardDatabase.getTotalCueCardCount(searchSelectedTags, searchText);
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

  void selectCard(CueCard? card) {
    selectedCard = card;
    notifyListeners();
  }

  Future<void> removeCueCard(int id) async {
    await _cueCardDatabase.deleteCueCard(id);
    
    await loadCueCards(page: _currentPage, size: _pageSize); // Reload paginated cards
    await loadRelationships(); // Reload relationships after delete
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

  List<CueCard> getParents(int childId) {
    final rel = relationships.where((r) => r.childId == childId).firstOrNull;
    if (rel == null) return [];
    final parent1 = cueCards.where((c) => c.id == rel.parent1Id).firstOrNull;
    final parent2 = cueCards.where((c) => c.id == rel.parent2Id).firstOrNull;
    return [if (parent1 != null) parent1, if (parent2 != null) parent2];
  }

  CueCard? getChild(int parent1Id, int parent2Id) {
    final rel = relationships.where((r) => (r.parent1Id == parent1Id && r.parent2Id == parent2Id) || (r.parent1Id == parent2Id && r.parent2Id == parent1Id)).firstOrNull;
    if (rel == null) return null;
    return cueCards.where((c) => c.id == rel.childId).firstOrNull;
  }
}