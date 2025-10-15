import 'package:dnd_cuecard_app/logic/cue_card_database.dart';
import 'package:dnd_cuecard_app/models/card_type.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/models/rarity.dart';
import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  static final CueCardDatabase _cueCardDatabase = CueCardDatabase();

  List<CueCard> cueCards = [];
  List<Rarity> rarities = [];
  List<CardType> cardTypes = [];
  List<Tag> tags = [];

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

  void selectCard(CueCard? card) {
    selectedCard = card;
    notifyListeners();
  }

  Future<void> removeCueCard(int id) async {
    await _cueCardDatabase.deleteCueCard(id);
    cueCards.removeWhere((card) => card.id == id);
    await loadCueCards(page: _currentPage, size: _pageSize); // Reload paginated cards
    notifyListeners();
  }

  void goToPage(int page) {
    if (page > 0 && page <= totalPages) {
      _currentPage = page;
      loadCueCards(page: _currentPage);
    }
  }

  void updateFilteredCueCards({List<Tag>? tags, String? text, int? size}) {
    if (size != null) _pageSize = size;
    if (tags != null) searchSelectedTags = tags;
    if (text != null) searchText = text;
    _currentPage = 1; // Reset to first page when page size changes
    loadCueCards(page: _currentPage, size: _pageSize);
  }
}