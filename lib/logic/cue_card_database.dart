import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/cue_card.dart';
import '../enums/card_type.dart';
import '../enums/rarity.dart';

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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dnd_cuecards.db');

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  Future<void> _onConfigure(Database db) {
    return db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) {
    return db.execute('''
      CREATE TABLE cue_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        requirements TEXT NOT NULL,
        description TEXT NOT NULL,
        box1 TEXT NOT NULL,
        box2 TEXT NOT NULL,
        notes TEXT,
        created_at TEXT,
        type TEXT NOT NULL,
        rarity TEXT NOT NULL,
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
    ''');
  }

  Future<int> insertCueCard(CueCard cueCard) async {
    final db = await database;
    int id = await db.insert('cue_cards', cueCard.toMapForInsert());
    for (String tagName in cueCard.tags) {
      await db.insert('tags', {'name': tagName}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('cue_card_tags', {'cue_card_id': id, 'tag_id': tagName});
    }
    return id;
  }

  Future<List<CueCard>> getAllCueCards() async {
    final db = await database;
    final List<Map<String, Object?>> cueCards = await db.query('cue_cards');
    return [
      for (final {
        'id' : id as int,
        'title' : title as String,
        'requirements' : requirements as String,
        'description' : description as String,
        'box1' : box1 as String,
        'box2' : box2 as String,
        'notes' : notes as String,
        'tags' : tags as List<String>,
        'dateCreated' : dateCreated as DateTime?,
        'type' : type as String,
        'rarity' : rarity as String,
        'icon' : icon as String?,
      } in cueCards)
      CueCard(id: id, title: title, requirements: requirements, description: description, box1: box1, box2: box2, notes: notes, tags: tags, dateCreated: dateCreated, type: CardType.values.byName(type), rarity: Rarity.values.byName(rarity), iconFilePath: icon),
    ];
  }

  Future<int> updateCueCard(CueCard cueCard) async {
    final db = await database;
    return await db.update(
      'cue_cards',
      cueCard.toMapForInsert(),
      where: 'id = ?',
      whereArgs: [cueCard.id],
    );
  }

  Future<int> deleteCueCard(int id) async {
    final db = await database;
    return await db.delete(
      'cue_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
