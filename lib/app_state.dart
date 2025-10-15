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

  Future<void> loadCueCards() async {
    cueCards = await _cueCardDatabase.getAllCueCards();
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
    notifyListeners();
  }
}