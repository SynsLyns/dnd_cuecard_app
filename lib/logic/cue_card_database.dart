import 'dart:async';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';

import '../models/card_type.dart';
import '../models/cue_card.dart';
import '../models/rarity.dart';

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

  Future<CueCard> getCueCard(int id) async {
    final db = await database;
    final List<Map<String, Object?>> cueCard = await db.query('cue_cards', where: 'id = ?', whereArgs: [id]);
    return CueCard.fromMap(cueCard[0]);
  }

  Future<List<CueCard>> getAllCueCards() async {
    final db = await database;
    final List<Map<String, Object?>> cueCards = await db.query('cue_cards');
    return [
      for (final {
        'id' : id as int?,
        'title' : title as String?,
        'requirements' : requirements as String?,
        'description' : description as String?,
        'box1' : box1 as String?,
        'box2' : box2 as String?,
        'notes' : notes as String?,
        'type' : type as int?,
        'rarity' : rarity as int?,
        'icon' : icon as String?,
      } in cueCards)
      CueCard(id: id, title: title, requirements: requirements, description: description, box1: box1, box2: box2, notes: notes, tags: [], dateCreated: null, type: type, rarity: rarity, iconFilePath: icon),
    ];
  }

  Future<int> updateCueCard(CueCard cueCard) async {
    final db = await database;
    int result = await db.update(
      'cue_cards',
      cueCard.toMapForInsert(),
      where: 'id = ?',
      whereArgs: [cueCard.id],
    );
    debugPrint('Updated cue card with id: ${cueCard.id}');
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
    return [
      for (final {
        'id' : id as int,
        'name' : name as String,
        'color' : color as int,
      } in rarities)
      Rarity(id: id, name: name, color: Color(color)),
    ];
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
    return [
      for (final {
        'id' : id as int,
        'name' : name as String,
        'color' : color as int,
      } in cardTypes)
      CardType(id: id, name: name, color: Color(color)),
    ];
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
}
