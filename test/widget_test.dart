import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:dnd_cuecard_app/models/initiative_app_state.dart';
import 'package:dnd_cuecard_app/models/initiative_item.dart';
import 'package:dnd_cuecard_app/widgets/tag/tag_chip.dart';

void main() {
  group('CueCard Model Tests', () {
    test('toMapForInsert and fromMap work correctly', () {
      final tags = [Tag(id: 1, name: 'Spell'), Tag(id: 2, name: 'Fire')];
      final card = CueCard(
        id: 42,
        title: 'Fireball',
        requirements: 'V, S, M',
        description: 'A bright streak flashes from your pointing finger...',
        box1: '8d6 fire damage',
        box2: 'Dex save halves',
        notes: 'Be careful of friendly fire',
        tags: tags,
        dateCreated: DateTime.parse('2026-01-01T12:00:00.000Z'),
        type: 1,
        rarity: 2,
        iconFilePath: 'assets/fire.png',
      );

      final map = card.toMapForInsert();
      expect(map['uuid'], isNotNull);
      expect((map['uuid'] as String).length, equals(36));
      expect(map['title'], equals('Fireball'));
      expect(map['requirements'], equals('V, S, M'));
      expect(map['description'], contains('bright streak'));
      expect(map['box1'], equals('8d6 fire damage'));
      expect(map['box2'], equals('Dex save halves'));
      expect(map['notes'], equals('Be careful of friendly fire'));
      expect(map['type'], equals(1));
      expect(map['rarity'], equals(2));
      expect(map['icon'], equals('assets/fire.png'));

      final reconstructed = CueCard.fromMap({
        'id': 42,
        ...map,
      }, tags);

      expect(reconstructed.id, equals(42));
      expect(reconstructed.uuid, equals(map['uuid']));
      expect(reconstructed.title, equals('Fireball'));
      expect(reconstructed.tags.length, equals(2));
      expect(reconstructed.tags[0].name, equals('Spell'));

      final copied = reconstructed.copyWith(title: 'Greater Fireball');
      expect(copied.id, equals(42));
      expect(copied.uuid, equals(reconstructed.uuid));
      expect(copied.title, equals('Greater Fireball'));
    });
  });

  group('InitiativeAppState Tests', () {
    test('addInitiativeItem sorts by initiative descending', () {
      final state = InitiativeAppState();

      state.addInitiativeItem(InitiativeItem(
        name: 'Goblin',
        initiative: 12,
        capacity: 1,
        cooldown: 2,
        hp: 7,
        maxHp: 7,
      ));

      state.addInitiativeItem(InitiativeItem(
        name: 'Rogue',
        initiative: 18,
        capacity: 1,
        cooldown: 1,
        hp: 20,
        maxHp: 20,
      ));

      expect(state.initiativeItems.first.name, equals('Rogue'));
      expect(state.initiativeItems.last.name, equals('Goblin'));
    });

    test('damage and heal clamp appropriately', () {
      final state = InitiativeAppState();
      state.addInitiativeItem(InitiativeItem(
        name: 'Paladin',
        initiative: 10,
        capacity: 1,
        cooldown: 1,
        hp: 15,
        maxHp: 20,
      ));

      state.damage(0, 10);
      expect(state.initiativeItems[0].hp, equals(5));

      state.damage(0, 50);
      expect(state.initiativeItems[0].hp, equals(0));

      state.heal(0, 100);
      expect(state.initiativeItems[0].hp, equals(20));
    });
  });

  group('TagChip Widget Tests', () {
    testWidgets('renders tag text correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TagChip(tag: 'Necromancy'),
          ),
        ),
      );

      expect(find.text('Necromancy'), findsOneWidget);
    });
  });
}
