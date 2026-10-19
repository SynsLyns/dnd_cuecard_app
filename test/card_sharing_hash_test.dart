import 'package:flutter_test/flutter_test.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:dnd_cuecard_app/models/relationship.dart';
import 'package:dnd_cuecard_app/logic/card_sharing_crypto.dart';

void main() {
  group('Phase 2: Shared Payload and Canonical Hash Tests', () {
    late CueCard baseCard;

    setUp(() {
      baseCard = CueCard(
        id: 1,
        uuid: '00000000-0000-0000-0000-000000000001',
        title: 'Magic Missile',
        requirements: 'V, S',
        description: 'You create three glowing darts of magical force...',
        box1: '1d4 + 1 force each',
        box2: 'Auto-hit',
        notes: 'Secret DM notes: can target objects if allowed by rule of cool',
        tags: [Tag(id: 1, name: 'Evocation'), Tag(id: 2, name: 'Force')],
        dateCreated: DateTime.parse('2026-03-01T10:00:00.000Z'),
        type: 1,
        rarity: 1,
        iconFilePath: 'C:/Users/Bill/icons/dart.png',
        relationship: Relationship(parent1Id: 10, parent2Id: 20, childId: 1),
      );
    });

    test('toSharedPayload excludes id, iconFilePath, and relationship, and includes notes and schema_version', () {
      final payload = baseCard.toSharedPayload();

      expect(payload['schema_version'], equals(1));
      expect(payload['uuid'], equals('00000000-0000-0000-0000-000000000001'));
      expect(payload['title'], equals('Magic Missile'));
      expect(payload['requirements'], equals('V, S'));
      expect(payload['description'], equals('You create three glowing darts of magical force...'));
      expect(payload['box1'], equals('1d4 + 1 force each'));
      expect(payload['box2'], equals('Auto-hit'));
      expect(payload['notes'], equals('Secret DM notes: can target objects if allowed by rule of cool'));
      expect(payload['type'], equals(1));
      expect(payload['rarity'], equals(1));
      expect(payload['tags'], equals(['Evocation', 'Force']));
      expect(payload['date_created'], equals('2026-03-01T10:00:00.000Z'));

      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('iconFilePath'), isFalse);
      expect(payload.containsKey('icon'), isFalse);
      expect(payload.containsKey('relationship'), isFalse);
    });

    test('identical cards give identical hashes', () {
      final card2 = CueCard(
        id: 999, // different local ID
        uuid: '00000000-0000-0000-0000-000000000001',
        title: 'Magic Missile',
        requirements: 'V, S',
        description: 'You create three glowing darts of magical force...',
        box1: '1d4 + 1 force each',
        box2: 'Auto-hit',
        notes: 'Secret DM notes: can target objects if allowed by rule of cool',
        tags: [Tag(id: 99, name: 'Evocation'), Tag(id: 88, name: 'Force')],
        dateCreated: DateTime.parse('2026-03-01T10:00:00.000Z'),
        type: 1,
        rarity: 1,
        iconFilePath: 'D:/different/path/icon.png', // different local icon
        relationship: null, // different local relationship
      );

      final hash1 = baseCard.canonicalHash();
      final hash2 = card2.canonicalHash();

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // SHA-256 hex string
    });

    test('key order does not affect the canonical hash', () {
      final mapA = {
        'schema_version': 1,
        'title': 'Test',
        'notes': 'Some notes',
        'tags': ['a', 'b'],
      };

      final mapB = {
        'tags': ['b', 'a'], // also testing tag order
        'notes': 'Some notes',
        'title': 'Test',
        'schema_version': 1,
      };

      final hashA = computeCanonicalHash(mapA);
      final hashB = computeCanonicalHash(mapB);

      expect(hashA, equals(hashB));
    });

    test('tag order does not affect the canonical hash', () {
      final cardWithReversedTags = baseCard.copyWith(
        tags: [Tag(id: 2, name: 'Force'), Tag(id: 1, name: 'Evocation')],
      );

      expect(baseCard.canonicalHash(), equals(cardWithReversedTags.canonicalHash()));
    });

    test('changing notes changes the canonical hash', () {
      final cardWithNewNotes = baseCard.copyWith(
        notes: 'Different DM notes',
      );
      expect(baseCard.canonicalHash(), isNot(equals(cardWithNewNotes.canonicalHash())));
    });

    test('changing any shared field changes the canonical hash', () {
      final baseHash = baseCard.canonicalHash();

      expect(baseCard.copyWith(title: 'Fireball').canonicalHash(), isNot(equals(baseHash)));
      expect(baseCard.copyWith(requirements: 'V').canonicalHash(), isNot(equals(baseHash)));
      expect(baseCard.copyWith(description: 'New text').canonicalHash(), isNot(equals(baseHash)));
      expect(baseCard.copyWith(box1: '2d6').canonicalHash(), isNot(equals(baseHash)));
      expect(baseCard.copyWith(box2: 'Reflex save').canonicalHash(), isNot(equals(baseHash)));
      expect(baseCard.copyWith(type: 2).canonicalHash(), isNot(equals(baseHash)));
      expect(baseCard.copyWith(rarity: 3).canonicalHash(), isNot(equals(baseHash)));
      expect(baseCard.copyWith(uuid: '00000000-0000-0000-0000-000000000099').canonicalHash(), isNot(equals(baseHash)));
      expect(baseCard.copyWith(tags: [Tag(name: 'Evocation')]).canonicalHash(), isNot(equals(baseHash)));
      expect(baseCard.copyWith(dateCreated: DateTime.parse('2026-05-01T00:00:00.000Z')).canonicalHash(), isNot(equals(baseHash)));
    });

    test('changing unshared fields does NOT change the canonical hash', () {
      final baseHash = baseCard.canonicalHash();

      // Changing id, iconFilePath, or relationship must NOT affect the hash
      expect(baseCard.copyWith(id: 777).canonicalHash(), equals(baseHash));
      expect(baseCard.copyWith(iconFilePath: 'C:/other/icon.png').canonicalHash(), equals(baseHash));
      expect(baseCard.copyWith(relationship: Relationship(parent1Id: 1, parent2Id: 2, childId: 3)).canonicalHash(), equals(baseHash));
    });
  });
}
