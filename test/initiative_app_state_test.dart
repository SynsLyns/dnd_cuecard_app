import 'package:dnd_cuecard_app/models/initiative_app_state.dart';
import 'package:dnd_cuecard_app/models/initiative_item.dart';
import 'package:dnd_cuecard_app/player/models/player_initiative.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('initiative player projection', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('restores a saved encounter and clears it when combat ends', () async {
      final original = InitiativeAppState();
      await original.initialize();
      final item = _combatant(visibility: InitiativeVisibility.full)
        ..cooldownTimers = [2, 1];
      original.addInitiativeItem(item);
      original.addInitiativeItem(_combatant(name: 'Goblin', hp: 8));
      original.setCurrentTurn(1);
      original.setHp(0, 7);
      await original.flushPendingPersistence();
      original.dispose();

      final separateCampaign = InitiativeAppState(campaignId: 'other-campaign');
      await separateCampaign.initialize();
      expect(separateCampaign.initiativeItems, isEmpty);
      separateCampaign.dispose();

      final restored = InitiativeAppState();
      await restored.initialize();

      expect(restored.initiativeItems, hasLength(2));
      expect(restored.currentTurnIndex, 1);
      expect(restored.initiativeItems.first.name, 'Guard');
      expect(restored.initiativeItems.first.hp, 7);
      expect(restored.initiativeItems.first.cooldownTimers, [2, 1]);
      expect(
        restored.initiativeItems.first.visibility,
        InitiativeVisibility.full,
      );

      await restored.endEncounter();
      await restored.flushPendingPersistence();

      final afterEnd = InitiativeAppState();
      await afterEnd.initialize();
      expect(afterEnd.initiativeItems, isEmpty);
      expect(afterEnd.currentTurnIndex, 0);

      restored.dispose();
      afterEnd.dispose();
    });

    test('new combatants default to limited visibility', () {
      final item = _combatant();

      expect(item.visibility, InitiativeVisibility.limited);
    });

    test('limited visibility exposes health status but no exact details', () {
      final state = InitiativeAppState()
        ..initiativeItems = [
          _combatant(visibility: InitiativeVisibility.limited),
        ];

      final combatant =
          (state.buildPlayerState()['combatants'] as List).single
              as Map<String, dynamic>;

      expect(combatant['health_status'], 'Bloodied');
      expect(combatant['name'], 'Guard');
      expect(combatant['initiative'], 12);
      expect(combatant.keys, isNot(contains('hp')));
      expect(combatant.keys, isNot(contains('max_hp')));
      expect(combatant.keys, isNot(contains('exhaustion')));
      expect(combatant.keys, isNot(contains('cooldown_timers')));
      expect(combatant.keys, isNot(contains('concentration')));
      expect(combatant.keys, isNot(contains('reaction_used')));
    });

    test('full visibility includes exact health and combat state', () {
      final item = _combatant(visibility: InitiativeVisibility.full)
        ..cooldownTimers = [1, 0];
      final state = InitiativeAppState()..initiativeItems = [item];

      final combatant =
          (state.buildPlayerState()['combatants'] as List).single
              as Map<String, dynamic>;

      expect(combatant['hp'], 10);
      expect(combatant['max_hp'], 20);
      expect(combatant['exhaustion'], 2);
      expect(combatant['concentration'], isTrue);
      expect(combatant['reaction_used'], isTrue);
      expect(combatant['capacity'], 2);
      expect(combatant['cooldown'], 3);
      expect(combatant['cooldown_timers'], [1, 0]);
    });

    test('hidden combatants are omitted without leaking the current turn', () {
      final state = InitiativeAppState()
        ..initiativeItems = [
          _combatant(name: 'Visible', visibility: InitiativeVisibility.full),
          _combatant(name: 'Secret', visibility: InitiativeVisibility.hidden),
        ]
        ..currentTurnIndex = 1;

      final combatants = state.buildPlayerState()['combatants'] as List;

      expect(combatants, hasLength(1));
      expect((combatants.single as Map)['name'], 'Visible');
      expect((combatants.single as Map)['is_current'], isFalse);
      expect(combatants.toString(), isNot(contains('Secret')));
    });

    test('ending combat clears the local tracker', () async {
      final state = InitiativeAppState()..initiativeItems = [_combatant()];

      await state.endEncounter();

      expect(state.initiativeItems, isEmpty);
      expect(state.currentTurnIndex, 0);
    });

    test('health labels use the expected thresholds', () {
      expect(_combatant(hp: 0).healthStatus, 'Down');
      expect(_combatant(hp: 5).healthStatus, 'Near Death');
      expect(_combatant(hp: 10).healthStatus, 'Bloodied');
      expect(_combatant(hp: 11).healthStatus, 'Healthy');
    });
  });

  test('player model reads the projected encounter payload', () {
    final encounter = PlayerInitiativeEncounter.fromJson({
      'schema_version': 1,
      'combatants': [
        {
          'name': 'Guard',
          'initiative': 12,
          'visibility': 'full',
          'health_status': 'Bloodied',
          'is_current': true,
          'hp': 10,
          'max_hp': 20,
          'exhaustion': 1,
          'concentration': true,
          'reaction_used': false,
          'capacity': 2,
          'cooldown': 3,
          'cooldown_timers': [1, 0],
        },
      ],
    });

    expect(encounter.combatants.single.name, 'Guard');
    expect(encounter.combatants.single.hp, 10);
    expect(encounter.combatants.single.isCurrent, isTrue);
  });
}

InitiativeItem _combatant({
  String name = 'Guard',
  int hp = 10,
  InitiativeVisibility visibility = InitiativeVisibility.limited,
}) {
  return InitiativeItem(
    name: name,
    initiative: 12,
    capacity: 2,
    cooldown: 3,
    hp: hp,
    maxHp: 20,
    exhaustion: 2,
    toggleState: true,
    cd1State: 1,
    visibility: visibility,
  );
}
