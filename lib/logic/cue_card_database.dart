import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/card_share.dart';
import '../models/card_type.dart';
import '../models/cue_card.dart';
import '../models/rarity.dart';
import '../models/relationship.dart';
import '../models/tag.dart';
import 'package:uuid/uuid.dart';

class CueCardDatabase {
  static final CueCardDatabase _instance = CueCardDatabase._internal();
  static Database? _database;

  factory CueCardDatabase() {
    return _instance;
  }

  CueCardDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
    }

    databaseFactory = databaseFactoryFfi;
    final dbPath = (await getApplicationSupportDirectory()).path;
    final path = join(dbPath, 'dnd_cuecards.db');

    return await openDatabase(
      path,
      version: 3,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) {
    return db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE cue_card_relationships (
          parent1_id INTEGER NOT NULL,
          parent2_id INTEGER NOT NULL,
          child_id INTEGER NOT NULL,
          PRIMARY KEY (parent1_id, parent2_id),
          UNIQUE (child_id),
          FOREIGN KEY (parent1_id) REFERENCES cue_cards(id) ON DELETE CASCADE,
          FOREIGN KEY (parent2_id) REFERENCES cue_cards(id) ON DELETE CASCADE,
          FOREIGN KEY (child_id) REFERENCES cue_cards(id) ON DELETE CASCADE,
          CHECK (parent1_id != parent2_id),
          CHECK (parent1_id < parent2_id)
        );
      ''');
    }
    if (oldVersion < 3) {
      // 1. Add uuid column to cue_cards
      await db.execute('ALTER TABLE cue_cards ADD COLUMN uuid TEXT;');

      // 2. Backfill a UUID v4 for every existing row
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

      // 3. Create unique index on uuid
      await db.execute('CREATE UNIQUE INDEX idx_cue_cards_uuid ON cue_cards (uuid);');

      // 4. Create card_shares table
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
  }

  Future<void> _onCreate(Database db, int version) {
    return db.execute('''
      CREATE TABLE cue_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
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
        PRIMARY KEY (cue_card_id, tag_id),
        FOREIGN KEY (cue_card_id) REFERENCES cue_cards(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
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
        PRIMARY KEY (parent1_id, parent2_id),
        UNIQUE (child_id),
        FOREIGN KEY (parent1_id) REFERENCES cue_cards(id) ON DELETE CASCADE,
        FOREIGN KEY (parent2_id) REFERENCES cue_cards(id) ON DELETE CASCADE,
        FOREIGN KEY (child_id) REFERENCES cue_cards(id) ON DELETE CASCADE,
        CHECK (parent1_id != parent2_id),
        CHECK (parent1_id < parent2_id)
      );

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

  Future<int> insertCueCard(CueCard cueCard) async {
    final db = await database;
    int id = await db.insert('cue_cards', cueCard.toMapForInsert());
    for (String tagName in cueCard.tags.map((tag) => tag.name)) {
      final tagId = await _getOrCreateTagId(db, tagName);
      await db.insert('cue_card_tags', {'cue_card_id': id, 'tag_id': tagId}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    return id;
  }

  Future<CueCard?> getCueCard(int id) async {
    final db = await database;
    final List<Map<String, Object?>> cueCard = await db.query('cue_cards', where: 'id = ?', whereArgs: [id]);
    if (cueCard.isEmpty) return null;
    final List<Tag> tags = await getTagsForCueCard(id);
    return CueCard.fromMap(cueCard[0], tags);
  }

  Future<CueCard?> getCueCardByUuid(String uuid) async {
    final db = await database;
    final List<Map<String, Object?>> cueCard = await db.query('cue_cards', where: 'uuid = ?', whereArgs: [uuid]);
    if (cueCard.isEmpty) return null;
    final int id = cueCard[0]['id'] as int;
    final List<Tag> tags = await getTagsForCueCard(id);
    return CueCard.fromMap(cueCard[0], tags);
  }

  Future<List<CueCard>> getAllCueCards() async {
    final db = await database;
    final List<Map<String, Object?>> cueCards = await db.query('cue_cards');
    List<CueCard> cueCardList = [];
    for (final cueCardMap in cueCards) {
      final int id = cueCardMap['id'] as int;
      final List<Tag> tags = await getTagsForCueCard(id);
      cueCardList.add(CueCard.fromMap(cueCardMap, tags));
    }
    return cueCardList;
  }

  Future<List<CueCard>> getPaginatedCueCards(List<Tag> selectedTags, String searchText, int limit, int offset) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (searchText.isNotEmpty) {
      whereClauses.add('LOWER(c.title) LIKE ?');
      whereArgs.add('%${searchText.toLowerCase()}%');
    }

    String tagJoin = '';
    String groupByHaving = '';

    if (selectedTags.isNotEmpty) {
      // Join cue_card_tags and tags
      tagJoin = '''
        INNER JOIN cue_card_tags AS cct ON c.id = cct.cue_card_id
        INNER JOIN tags AS t ON cct.tag_id = t.id
      ''';

      // Filter by selected tag IDs
      final tagIds = selectedTags.map((t) => t.id).whereType<int>().toList();
      whereClauses.add('t.id IN (${List.filled(tagIds.length, '?').join(',')})');
      whereArgs.addAll(tagIds);

      // Ensure all selected tags are matched
      groupByHaving = 'GROUP BY c.id HAVING COUNT(DISTINCT t.id) = ${tagIds.length}';
    }

    final whereString = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final query = '''
      SELECT c.*
      FROM cue_cards AS c
      $tagJoin
      $whereString
      $groupByHaving
      ORDER BY c.id ASC
      LIMIT ?
      OFFSET ?
    ''';

    final result = await db.rawQuery(query, [...whereArgs, limit, offset]);

    List<CueCard> cueCardList = [];
    for (final cueCardMap in result) {
      final int id = cueCardMap['id'] as int;
      final List<Tag> tags = await getTagsForCueCard(id);
      cueCardList.add(CueCard.fromMap(cueCardMap, tags));
    }
    return cueCardList;
  }

  Future<int> getTotalCueCardCount([List<Tag>? selectedTags, String? searchText]) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (searchText != null && searchText.isNotEmpty) {
      whereClauses.add('LOWER(c.title) LIKE ?');
      whereArgs.add('%${searchText.toLowerCase()}%');
    }

    String tagJoin = '';
    String groupByHaving = '';

    if (selectedTags != null && selectedTags.isNotEmpty) {
      // Join cue_card_tags and tags
      tagJoin = '''
        INNER JOIN cue_card_tags AS cct ON c.id = cct.cue_card_id
        INNER JOIN tags AS t ON cct.tag_id = t.id
      ''';

      // Filter by selected tag IDs
      final tagIds = selectedTags.map((t) => t.id).whereType<int>().toList();
      whereClauses.add('t.id IN (${List.filled(tagIds.length, '?').join(',')})');
      whereArgs.addAll(tagIds);

      // Ensure all selected tags are matched
      groupByHaving = 'GROUP BY c.id HAVING COUNT(DISTINCT t.id) = ${tagIds.length}';
    }

    final whereString = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final query = '''
      SELECT COUNT(*)
      FROM (
        SELECT c.id
        FROM cue_cards AS c
        $tagJoin
        $whereString
        $groupByHaving
      ) AS filtered_cue_cards
    ''';

    final count = Sqflite.firstIntValue(await db.rawQuery(query, whereArgs));
    return count ?? 0;
  }

  Future<List<Tag>> getTagsForCueCard(int cueCardId) async {
    final db = await database;
    final List<Map<String, Object?>> tagMaps = await db.rawQuery('''
      SELECT T.id, T.name FROM tags AS T
      INNER JOIN cue_card_tags AS CCT ON T.id = CCT.tag_id
      WHERE CCT.cue_card_id = ?
    ''', [cueCardId]);
    return tagMaps.map((map) => Tag.fromMap(map)).toList();
  }

  Future<int> updateCueCard(CueCard cueCard) async {
    final db = await database;
    Map<String, Object?> updateMap = cueCard.toMapForInsert();
    if (cueCard.uuid == null) {
      final existing = await db.query('cue_cards', columns: ['uuid'], where: 'id = ?', whereArgs: [cueCard.id]);
      if (existing.isNotEmpty && existing.first['uuid'] != null) {
        updateMap['uuid'] = existing.first['uuid'];
      }
    }
    int result = await db.update(
      'cue_cards',
      updateMap,
      where: 'id = ?',
      whereArgs: [cueCard.id],
    );
    await db.delete('cue_card_tags', where: 'cue_card_id = ?', whereArgs: [cueCard.id]);
    for (String tagName in cueCard.tags.map((tag) => tag.name)) {
      final tagId = await _getOrCreateTagId(db, tagName);
      await db.insert('cue_card_tags', {'cue_card_id': cueCard.id, 'tag_id': tagId}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    return result;
  }

  Future<int> deleteCueCard(int id) async {
    final db = await database;
    return await db.delete(
      'cue_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Rarity>> getRarities() async {
    final db = await database;
    final List<Map<String, Object?>> rarities = await db.query('rarities');
    return rarities.map((map) => Rarity.fromMap(map)).toList();
  }

  Future<int> insertRarity(Rarity rarity) async {
    final db = await database;
    return await db.insert('rarities', rarity.toMapForInsert());
  }

  Future<int> updateRarity(Rarity rarity) async {
    final db = await database;
    return await db.update(
      'rarities',
      rarity.toMapForInsert(),
      where: 'id = ?',
      whereArgs: [rarity.id],
    );
  }

  Future<int> deleteRarity(int id) async {
    final db = await database;
    return await db.delete(
      'rarities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<CardType>> getCardTypes() async {
    final db = await database;
    final List<Map<String, Object?>> cardTypes = await db.query('card_types');
    return cardTypes.map((map) => CardType.fromMap(map)).toList();
  }

  Future<int> insertCardType(CardType cardType) async {
    final db = await database;
    return await db.insert('card_types', cardType.toMapForInsert());
  }

  Future<int> updateCardType(CardType cardType) async {
    final db = await database;
    return await db.update(
      'card_types',
      cardType.toMapForInsert(),
      where: 'id = ?',
      whereArgs: [cardType.id],
    );
  }

  Future<int> deleteCardType(int id) async {
    final db = await database;
    return await db.delete(
      'card_types',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Tag>> getTags() async {
    final db = await database;
    final List<Map<String, Object?>> tags = await db.query('tags');
    return tags.map((map) => Tag.fromMap(map)).toList();
  }

  Future<int> insertTag(Tag tag) async {
    final db = await database;
    return await db.insert('tags', tag.toMapForInsert());
  }

  Future<int> updateTag(Tag tag) async {
    final db = await database;
    return await db.update(
      'tags',
      tag.toMapForInsert(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  Future<int> deleteTag(int id) async {
    final db = await database;
    return await db.delete(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> rarityNameExists(String name, [int? id]) async {
    final db = await database;
    List<Map<String, Object?>> result;
    if (id == null) {
      result = await db.query('rarities', where: 'name = ?', whereArgs: [name]);
    } else {
      result = await db.query('rarities', where: 'name = ? AND id != ?', whereArgs: [name, id]);
    }
    return result.isNotEmpty;
  }

  Future<bool> cardTypeNameExists(String name, [int? id]) async {
    final db = await database;
    List<Map<String, Object?>> result;
    if (id == null) {
      result = await db.query('card_types', where: 'name = ?', whereArgs: [name]);
    } else {
      result = await db.query('card_types', where: 'name = ? AND id != ?', whereArgs: [name, id]);
    }
    return result.isNotEmpty;
  }

  Future<bool> tagNameExists(String name, [int? id]) async {
    final db = await database;
    List<Map<String, Object?>> result;
    if (id == null) {
      result = await db.query('tags', where: 'name = ?', whereArgs: [name]);
    } else {
      result = await db.query('tags', where: 'name = ? AND id != ?', whereArgs: [name, id]);
    }
    return result.isNotEmpty;
  }

  Future<int> _getOrCreateTagId(Database db, String tagName) async {
    final List<Map<String, Object?>> existingTags = await db.query(
      'tags',
      where: 'name = ?',
      whereArgs: [tagName],
    );

    if (existingTags.isNotEmpty) {
      return existingTags.first['id'] as int;
    } else {
      return await db.insert('tags', {'name': tagName});
    }
  }

  Future<int> insertRelationship(Relationship relationship) async {
    final db = await database;
    return await db.insert('cue_card_relationships', relationship.toMap());
  }

  Future<Relationship?> getRelationshipByParents(int parent1Id, int parent2Id) async {
    final db = await database;
    final int p1 = parent1Id < parent2Id ? parent1Id : parent2Id;
    final int p2 = parent1Id < parent2Id ? parent2Id : parent1Id;
    final List<Map<String, Object?>> maps = await db.query(
      'cue_card_relationships',
      where: 'parent1_id = ? AND parent2_id = ?',
      whereArgs: [p1, p2],
    );
    if (maps.isNotEmpty) {
      return Relationship.fromMap(maps.first);
    }
    return null;
  }

  Future<Relationship?> getRelationshipByChild(int childId) async {
    final db = await database;
    final List<Map<String, Object?>> maps = await db.query(
      'cue_card_relationships',
      where: 'child_id = ?',
      whereArgs: [childId],
    );
    if (maps.isNotEmpty) {
      return Relationship.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteRelationship(int parent1Id, int parent2Id) async {
    final db = await database;
    final int p1 = parent1Id < parent2Id ? parent1Id : parent2Id;
    final int p2 = parent1Id < parent2Id ? parent2Id : parent1Id;
    return await db.delete(
      'cue_card_relationships',
      where: 'parent1_id = ? AND parent2_id = ?',
      whereArgs: [p1, p2],
    );
  }

  Future<List<Relationship>> getAllRelationships() async {
    final db = await database;
    final List<Map<String, Object?>> maps = await db.query('cue_card_relationships');
    return maps.map((map) => Relationship.fromMap(map)).toList();
  }

  // --- card_shares methods ---

  Future<int> insertOrUpdateCardShare(CardShare share) async {
    final db = await database;
    return await db.insert(
      'card_shares',
      share.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<CardShare?> getCardShare(String cardUuid, String campaignId) async {
    final db = await database;
    final maps = await db.query(
      'card_shares',
      where: 'card_uuid = ? AND campaign_id = ?',
      whereArgs: [cardUuid, campaignId],
    );
    if (maps.isNotEmpty) {
      return CardShare.fromMap(maps.first);
    }
    return null;
  }

  Future<List<CardShare>> getCardSharesForCard(String cardUuid) async {
    final db = await database;
    final maps = await db.query(
      'card_shares',
      where: 'card_uuid = ?',
      whereArgs: [cardUuid],
    );
    return maps.map((map) => CardShare.fromMap(map)).toList();
  }

  Future<int> deleteCardShare(String cardUuid, String campaignId) async {
    final db = await database;
    return await db.delete(
      'card_shares',
      where: 'card_uuid = ? AND campaign_id = ?',
      whereArgs: [cardUuid, campaignId],
    );
  }

  Future<int> deleteCardSharesForCard(String cardUuid) async {
    final db = await database;
    return await db.delete(
      'card_shares',
      where: 'card_uuid = ?',
      whereArgs: [cardUuid],
    );
  }
}

