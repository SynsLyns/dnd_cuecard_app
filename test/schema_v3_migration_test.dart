import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/models/card_share.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Phase 1 Schema v3 Migration Tests', () {
    test('upgrades v2 database to v3, backfills UUIDs, and creates card_shares', () async {
      // 1. Create a version 2 database with existing data (no uuid column)
      final tempDir = await Directory.systemTemp.createTemp('cuecard_migration_test_');
      final dbPath = p.join(tempDir.path, 'migration_test.db');
      Database db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE cue_cards (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT,
                requirements TEXT,
                description TEXT,
                box1 TEXT,
                box2 TEXT,
                notes TEXT,
                date_created TEXT,
                type INTEGER,
                rarity INTEGER,
                icon TEXT
              );
              CREATE TABLE tags (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE
              );
              CREATE TABLE cue_card_tags (
                cue_card_id INTEGER NOT NULL,
                tag_id INTEGER NOT NULL,
                PRIMARY KEY (cue_card_id, tag_id)
              );
              CREATE TABLE rarities (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                color INTEGER NOT NULL
              );
              CREATE TABLE card_types (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                color INTEGER NOT NULL
              );
              CREATE TABLE cue_card_relationships (
                parent1_id INTEGER NOT NULL,
                parent2_id INTEGER NOT NULL,
                child_id INTEGER NOT NULL,
                PRIMARY KEY (parent1_id, parent2_id)
              );
            ''');

            // Insert 2 cards into v2 schema
            await db.insert('cue_cards', {'title': 'Card A', 'type': 1, 'rarity': 1});
            await db.insert('cue_cards', {'title': 'Card B', 'type': 2, 'rarity': 2});
          },
        ),
      );

      // Verify v2 cards have no uuid
      final v2Cards = await db.query('cue_cards');
      expect(v2Cards.length, equals(2));
      expect(v2Cards.first.containsKey('uuid'), isFalse);
      await db.close();

      // 2. Now upgrade to version 3 using the migration logic
      db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 3,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 3) {
              await db.execute('ALTER TABLE cue_cards ADD COLUMN uuid TEXT;');

              final List<Map<String, Object?>> rows = await db.query('cue_cards', columns: ['id']);
              const uuidGenerator = Uuid();
              for (final row in rows) {
                final id = row['id'] as int;
                final generatedUuid = uuidGenerator.v4();
                await db.update(
                  'cue_cards',
                  {'uuid': generatedUuid},
                  where: 'id = ?',
                  whereArgs: [id],
                );
              }

              await db.execute('CREATE UNIQUE INDEX idx_cue_cards_uuid ON cue_cards (uuid);');

              await db.execute('''
                CREATE TABLE card_shares (
                  card_uuid TEXT NOT NULL,
                  campaign_id TEXT NOT NULL,
                  shared_card_id TEXT NOT NULL,
                  pushed_version INTEGER NOT NULL,
                  pushed_hash TEXT NOT NULL,
                  pushed_at TEXT NOT NULL,
                  PRIMARY KEY (card_uuid, campaign_id)
                );
              ''');
            }
          },
        ),
      );

      // 3. Verify upgraded data
      final v3Cards = await db.query('cue_cards');
      expect(v3Cards.length, equals(2));

      final card1 = v3Cards[0];
      final card2 = v3Cards[1];

      expect(card1['title'], equals('Card A'));
      expect(card2['title'], equals('Card B'));

      final uuid1 = card1['uuid'] as String?;
      final uuid2 = card2['uuid'] as String?;

      expect(uuid1, isNotNull);
      expect(uuid2, isNotNull);
      expect(uuid1, isNotEmpty);
      expect(uuid2, isNotEmpty);
      expect(uuid1, isNot(equals(uuid2)));

      // 4. Verify card_shares table works
      final share = CardShare(
        cardUuid: uuid1!,
        campaignId: 'camp-123',
        sharedCardId: 'shared-456',
        pushedVersion: 1,
        pushedHash: 'hash-abc',
        pushedAt: DateTime.parse('2026-10-18T12:00:00Z'),
      );

      await db.insert('card_shares', share.toMap());
      final shares = await db.query('card_shares', where: 'card_uuid = ?', whereArgs: [uuid1]);
      expect(shares.length, equals(1));
      expect(CardShare.fromMap(shares.first).campaignId, equals('camp-123'));

      // 5. Verify inserting a new CueCard automatically gets a UUID
      final newCard = CueCard(title: 'New Card C', type: 1, rarity: 1);
      final insertMap = newCard.toMapForInsert();
      expect(insertMap['uuid'], isNotNull);
      expect((insertMap['uuid'] as String).length, equals(36)); // v4 UUID length

      final newId = await db.insert('cue_cards', insertMap);
      final fetched = await db.query('cue_cards', where: 'id = ?', whereArgs: [newId]);
      expect(fetched.first['uuid'], equals(insertMap['uuid']));

      await db.close();
    });
  });
}
