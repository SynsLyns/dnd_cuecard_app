import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/logic/cue_card_creator.dart';
import 'package:dnd_cuecard_app/models/card_type.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/models/rarity.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CueCardFormControllers {
  final titleController = TextEditingController();
  final requirementsController = TextEditingController();
  final descriptionController = TextEditingController();
  final notesController = TextEditingController();
  final box1Controller = TextEditingController();
  final box2Controller = TextEditingController();
  final cardTypeController = TextEditingController();
  final rarityController = TextEditingController();

  void dispose() {
    titleController.dispose();
    requirementsController.dispose();
    descriptionController.dispose();
    notesController.dispose();
    box1Controller.dispose();
    box2Controller.dispose();
    cardTypeController.dispose();
    rarityController.dispose();
  }

  void loadCard(CueCard card, AppState appState) {
    titleController.text = card.title ?? '';
    requirementsController.text = card.requirements ?? '';
    descriptionController.text = card.description ?? '';
    notesController.text = card.notes ?? '';
    box1Controller.text = card.box1 ?? '';
    box2Controller.text = card.box2 ?? '';
    
    List<CardType> cardTypes = appState.cardTypes;
    List<Rarity> rarities = appState.rarities;
    final cardType = cardTypes
      .where((type) => type.id == card.type)
      .firstOrNull;
    final rarity = rarities
      .where((r) => r.id == card.rarity)
      .firstOrNull;
    
    cardTypeController.text = cardType?.name ?? '';    
    rarityController.text = rarity?.name ?? '';
  }

  Future<void> saveCueCard(AppState appState, XFile? image) async {
    List<CardType> cardTypes = appState.cardTypes;
    List<Rarity> rarities = appState.rarities;
    if (appState.selectedCard != null) {
      // Update existing card
      await CueCardCreator.updateCueCard(
        appState.selectedCard!.id!,
        titleController.text,
        requirementsController.text,
        descriptionController.text,
        box1Controller.text,
        box2Controller.text,
        notesController.text,
        [],
        cardTypeController.text.isEmpty ? null : cardTypes.firstWhere((type) => type.name == cardTypeController.text).id,
        rarityController.text.isEmpty ? null : rarities.firstWhere((r) => r.name == rarityController.text).id,
        image?.path,
      );
    } else {
      // Create new card
      await CueCardCreator.createCueCard(
        titleController.text,
        requirementsController.text,
        descriptionController.text,
        box1Controller.text,
        box2Controller.text,
        notesController.text,
        [],
        cardTypeController.text.isEmpty ? null : cardTypes.firstWhere((type) => type.name == cardTypeController.text).id,
        rarityController.text.isEmpty ? null : rarities.firstWhere((r) => r.name == rarityController.text).id,
        image?.path,
      );
    }
    
    clearCueCard(appState);
    await appState.loadCueCards();
  }
  
  void clearCueCard(AppState appState) {
    titleController.clear();
    requirementsController.clear();
    descriptionController.clear();
    box1Controller.clear();
    box2Controller.clear();
    notesController.clear();
    cardTypeController.clear();
    rarityController.clear();
    appState.selectCard(null);
  }
}
