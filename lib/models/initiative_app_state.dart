import 'package:flutter/material.dart';
import 'initiative_item.dart';

class InitiativeAppState extends ChangeNotifier {
  List<InitiativeItem> initiativeItems = [];
  int currentTurnIndex = 0;

  void addInitiativeItem(InitiativeItem item) {
    initiativeItems.add(item);
    initiativeItems.sort((a, b) => b.initiative.compareTo(a.initiative));
    notifyListeners();
  }

  void removeInitiativeItem(int index) {
    initiativeItems.removeAt(index);
    // Adjust current turn index if necessary
    if (initiativeItems.isEmpty) {
      currentTurnIndex = 0;
    } else if (currentTurnIndex >= initiativeItems.length) {
      currentTurnIndex = 0;
    }
    notifyListeners();
  }

  void nextTurn() {
    if (initiativeItems.isNotEmpty) {
      // Move to next person first
      currentTurnIndex = (currentTurnIndex + 1) % initiativeItems.length;
      // Then tick down the new current person's cooldowns
      initiativeItems[currentTurnIndex].nextTurn();
    }
    notifyListeners();
  }

  void startCooldown(int itemIndex, int chargeIndex) {
    initiativeItems[itemIndex].startCooldown(chargeIndex);
    notifyListeners();
  }

  void decrementCooldown(int itemIndex, int chargeIndex) {
    if (initiativeItems[itemIndex].cooldownTimers[chargeIndex] > 0) {
      initiativeItems[itemIndex].cooldownTimers[chargeIndex]--;
      notifyListeners();
    }
  }

  void setCurrentTurn(int index) {
    if (index >= 0 && index < initiativeItems.length) {
      currentTurnIndex = index;
      // Tick down the cooldowns for this person's turn
      initiativeItems[currentTurnIndex].nextTurn();
      notifyListeners();
    }
  }
}
