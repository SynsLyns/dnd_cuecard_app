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

  void damage(int index, int amount) {
    final item = initiativeItems[index];
    item.hp = (item.hp - amount).clamp(0, item.maxHp);
    notifyListeners();
  }

  void heal(int index, int amount) {
    final item = initiativeItems[index];
    item.hp = (item.hp + amount).clamp(0, item.maxHp);
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

  void incrementExhaustion(int index) {
    final item = initiativeItems[index];
    item.exhaustion = (item.exhaustion + 1).clamp(0, 6);
    notifyListeners();
  }

  void decrementExhaustion(int index) {
    final item = initiativeItems[index];
    item.exhaustion = (item.exhaustion - 1).clamp(0, 6);
    notifyListeners();
  }

  void setHp(int index, int hp) {
    final item = initiativeItems[index];
    item.hp = hp.clamp(0, item.maxHp);
    notifyListeners();
  }

  void setMaxHp(int index, int maxHp) {
    final item = initiativeItems[index];
    item.maxHp = maxHp.clamp(1, 99999);
    if (item.hp > item.maxHp) {
      item.hp = item.maxHp;
    }
    notifyListeners();
  }

  void toggleToggleState(int index) {
    initiativeItems[index].toggleToggle();
    notifyListeners();
  }

  void startCd1(int index) {
    initiativeItems[index].startCd1();
    notifyListeners();
  }

  void decrementCd1(int index) {
    initiativeItems[index].decrementCd1();
    notifyListeners();
  }
}
