import 'package:dnd_cuecard_app/player/models/player_shared_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerSharedCard', () {
    test('reads known shared fields and styling metadata', () {
      final card = PlayerSharedCard.fromMap({
        'id': 'shared-id',
        'schema_version': 1,
        'version': 3,
        'payload': {
          'title': 'Fireball',
          'requirements': 'V, S',
          'description': 'A bright streak flashes.',
          'notes': 'Aim carefully.',
          'box1': '8d6 fire',
          'box2': '20-foot radius',
          'type_name': 'Spell',
          'type_color': 4278255360,
          'rarity_name': 'Rare',
          'rarity_color': 4294901760,
          'tags': ['Evocation', 'Fire'],
        },
      });

      expect(card.id, 'shared-id');
      expect(card.version, 3);
      expect(card.title, 'Fireball');
      expect(card.requirements, 'V, S');
      expect(card.description, 'A bright streak flashes.');
      expect(card.notes, 'Aim carefully.');
      expect(card.box1, '8d6 fire');
      expect(card.box2, '20-foot radius');
      expect(card.typeName, 'Spell');
      expect(card.typeColor, 4278255360);
      expect(card.rarityName, 'Rare');
      expect(card.rarityColor, 4294901760);
      expect(card.tags, ['Evocation', 'Fire']);
    });

    test('tolerates newer schemas and missing or malformed fields', () {
      final card = PlayerSharedCard.fromMap({
        'id': 42,
        'schema_version': 99,
        'version': 2.7,
        'payload': {'title': 123, 'tags': 'not a list', 'requirements': ''},
      });

      expect(card.id, '42');
      expect(card.schemaVersion, 99);
      expect(card.version, 2);
      expect(card.title, 'Untitled card');
      expect(card.requirements, isNull);
      expect(card.description, isNull);
      expect(card.tags, isEmpty);
    });

    test('uses safe defaults for an absent payload', () {
      final card = PlayerSharedCard.fromMap({'id': 'empty'});

      expect(card.title, 'Untitled card');
      expect(card.payload, isEmpty);
      expect(card.schemaVersion, 1);
      expect(card.version, 1);
    });

    test('searches card titles and tags case-insensitively', () {
      final card = PlayerSharedCard.fromMap({
        'id': 'searchable',
        'payload': {
          'title': 'Beginner Water Magic',
          'tags': ['Evocation', 'Water'],
        },
      });

      expect(card.matchesSearch('water magic'), isTrue);
      expect(card.matchesSearch('EVO'), isTrue);
      expect(card.matchesSearch('weapon'), isFalse);
      expect(card.matchesSearch('  '), isTrue);
    });
  });
}
