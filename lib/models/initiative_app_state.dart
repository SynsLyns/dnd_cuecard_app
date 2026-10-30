import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dnd_cuecard_app/logic/supabase_service.dart';
import 'initiative_item.dart';

class InitiativeAppState extends ChangeNotifier {
  InitiativeAppState({this.campaignId});

  final String? campaignId;
  final SupabaseService _supabaseService = SupabaseService();
  late final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  List<InitiativeItem> initiativeItems = [];
  int currentTurnIndex = 0;
  bool isLoadingSavedState = false;
  String? persistenceError;
  bool isSyncing = false;
  String? syncError;
  Future<void> _syncQueue = Future<void>.value();
  Future<void> _persistenceQueue = Future<void>.value();
  Future<void>? _initialization;
  bool _hasLoadedSavedState = false;
  bool _isEnding = false;
  bool _isDisposed = false;

  String get _persistenceKey => 'initiative_encounter_${campaignId ?? 'local'}';

  Future<void> initialize() => _initialization ??= _loadSavedState();

  Future<void> flushPendingPersistence() => _persistenceQueue;

  Future<void> _loadSavedState() async {
    isLoadingSavedState = true;
    notifyListeners();
    try {
      final savedState = await _preferences.getString(_persistenceKey);
      if (savedState != null) {
        final decoded = jsonDecode(savedState);
        if (decoded is! Map<String, dynamic> ||
            decoded['schema_version'] != 1 ||
            decoded['combatants'] is! List ||
            decoded['current_turn_index'] is! int) {
          throw const FormatException('Invalid saved initiative encounter.');
        }

        final savedItems = (decoded['combatants'] as List).map((combatant) {
          if (combatant is! Map) {
            throw const FormatException('Invalid saved initiative item.');
          }
          return InitiativeItem.fromJson(Map<String, dynamic>.from(combatant));
        }).toList();
        final savedTurnIndex = decoded['current_turn_index'] as int;
        if (savedItems.isEmpty
            ? savedTurnIndex != 0
            : savedTurnIndex < 0 || savedTurnIndex >= savedItems.length) {
          throw const FormatException('Invalid saved initiative turn.');
        }

        initiativeItems = savedItems;
        currentTurnIndex = savedTurnIndex;
      }
      _hasLoadedSavedState = true;
      persistenceError = null;
    } catch (exception) {
      persistenceError = 'Could not restore the saved encounter: $exception';
      _hasLoadedSavedState = true;
    } finally {
      isLoadingSavedState = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> _persistSavedState() {
    if (!_hasLoadedSavedState || _isDisposed) return Future<void>.value();

    final snapshot = jsonEncode({
      'schema_version': 1,
      'current_turn_index': currentTurnIndex,
      'combatants': initiativeItems.map((item) => item.toJson()).toList(),
    });
    _persistenceQueue = _persistenceQueue.then((_) async {
      try {
        await _preferences.setString(_persistenceKey, snapshot);
        if (persistenceError != null) {
          persistenceError = null;
          if (!_isDisposed) notifyListeners();
        }
      } catch (exception) {
        persistenceError = 'Could not save the encounter locally: $exception';
        if (!_isDisposed) notifyListeners();
      }
    });
    return _persistenceQueue;
  }

  void addInitiativeItem(InitiativeItem item) {
    final currentItem =
        initiativeItems.isNotEmpty &&
            currentTurnIndex >= 0 &&
            currentTurnIndex < initiativeItems.length
        ? initiativeItems[currentTurnIndex]
        : null;
    initiativeItems.add(item);
    initiativeItems.sort((a, b) => b.initiative.compareTo(a.initiative));
    if (currentItem != null) {
      currentTurnIndex = initiativeItems.indexOf(currentItem);
    }
    _notifyAndSync();
  }

  void removeInitiativeItem(int index) {
    if (index < 0 || index >= initiativeItems.length) return;
    initiativeItems.removeAt(index);
    if (initiativeItems.isEmpty) {
      currentTurnIndex = 0;
    } else if (index < currentTurnIndex) {
      currentTurnIndex--;
    } else if (currentTurnIndex >= initiativeItems.length) {
      currentTurnIndex = 0;
    }
    _notifyAndSync();
  }

  void nextTurn() {
    if (initiativeItems.isNotEmpty) {
      currentTurnIndex = (currentTurnIndex + 1) % initiativeItems.length;
      initiativeItems[currentTurnIndex].nextTurn();
    }
    _notifyAndSync();
  }

  void damage(int index, int amount) {
    final item = initiativeItems[index];
    item.hp = (item.hp - amount).clamp(0, item.maxHp);
    _notifyAndSync();
  }

  void heal(int index, int amount) {
    final item = initiativeItems[index];
    item.hp = (item.hp + amount).clamp(0, item.maxHp);
    _notifyAndSync();
  }

  void startCooldown(int itemIndex, int chargeIndex) {
    initiativeItems[itemIndex].startCooldown(chargeIndex);
    _notifyAndSync();
  }

  void decrementCooldown(int itemIndex, int chargeIndex) {
    if (initiativeItems[itemIndex].cooldownTimers[chargeIndex] > 0) {
      initiativeItems[itemIndex].cooldownTimers[chargeIndex]--;
      _notifyAndSync();
    }
  }

  void setCurrentTurn(int index) {
    if (index >= 0 && index < initiativeItems.length) {
      currentTurnIndex = index;
      initiativeItems[currentTurnIndex].nextTurn();
      _notifyAndSync();
    }
  }

  void incrementExhaustion(int index) {
    final item = initiativeItems[index];
    item.exhaustion = (item.exhaustion + 1).clamp(0, 6);
    _notifyAndSync();
  }

  void decrementExhaustion(int index) {
    final item = initiativeItems[index];
    item.exhaustion = (item.exhaustion - 1).clamp(0, 6);
    _notifyAndSync();
  }

  void setHp(int index, int hp) {
    final item = initiativeItems[index];
    item.hp = hp.clamp(0, item.maxHp);
    _notifyAndSync();
  }

  void setMaxHp(int index, int maxHp) {
    final item = initiativeItems[index];
    item.maxHp = maxHp.clamp(1, 99999);
    if (item.hp > item.maxHp) {
      item.hp = item.maxHp;
    }
    _notifyAndSync();
  }

  void toggleToggleState(int index) {
    initiativeItems[index].toggleToggle();
    _notifyAndSync();
  }

  void startCd1(int index) {
    initiativeItems[index].startCd1();
    _notifyAndSync();
  }

  void decrementCd1(int index) {
    initiativeItems[index].decrementCd1();
    _notifyAndSync();
  }

  void setVisibility(int index, InitiativeVisibility visibility) {
    if (index < 0 || index >= initiativeItems.length) return;
    initiativeItems[index].visibility = visibility;
    _notifyAndSync();
  }

  Map<String, dynamic> buildPlayerState() {
    return {
      'schema_version': 1,
      'combatants': [
        for (var index = 0; index < initiativeItems.length; index++)
          if (initiativeItems[index].visibility != InitiativeVisibility.hidden)
            _combatantPlayerState(index, initiativeItems[index]),
      ],
    };
  }

  Map<String, dynamic> _combatantPlayerState(int index, InitiativeItem item) {
    return {
      'name': item.name,
      'initiative': item.initiative,
      'visibility': item.visibility.name,
      'health_status': item.healthStatus,
      'is_current': index == currentTurnIndex,
      if (item.visibility == InitiativeVisibility.full) ...{
        'hp': item.hp,
        'max_hp': item.maxHp,
        'exhaustion': item.exhaustion,
        'concentration': item.toggleState,
        'reaction_used': item.cd1State > 0,
        'capacity': item.capacity,
        'cooldown': item.cooldown,
        'cooldown_timers': item.cooldownTimers,
      },
    };
  }

  Future<void> endEncounter() async {
    _isEnding = true;
    await _syncQueue;
    await _persistenceQueue;
    try {
      final id = campaignId;
      if (id != null) {
        await _supabaseService.clearInitiativeEncounter(id);
      }
      initiativeItems.clear();
      currentTurnIndex = 0;
      syncError = null;
      await _persistSavedState();
    } catch (exception) {
      syncError = 'Could not end the shared encounter: $exception';
    } finally {
      _isEnding = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void _notifyAndSync() {
    notifyListeners();
    unawaited(_persistSavedState());
    final id = campaignId;
    if (id == null || _isEnding) return;

    final playerState = buildPlayerState();
    _syncQueue = _syncQueue.then((_) async {
      if (_isDisposed || _isEnding) return;
      isSyncing = true;
      notifyListeners();
      try {
        await _supabaseService.publishInitiativeEncounter(
          campaignId: id,
          playerState: playerState,
        );
        syncError = null;
      } catch (exception) {
        syncError = 'Could not share initiative with players: $exception';
      } finally {
        isSyncing = false;
        if (!_isDisposed) notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
