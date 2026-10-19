import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:uuid/uuid.dart';
import 'relationship.dart';
import '../logic/card_sharing_crypto.dart';

class CueCard {
  final int? id;
  final String? uuid;
  final String? title;
  final String? requirements;
  final String? description;
  final String? box1;
  final String? box2;
  final String? notes;
  final List<Tag> tags;
  final DateTime? dateCreated;
  final int? type;
  final int? rarity;
  final String? iconFilePath;
  final Relationship? relationship;

  CueCard({
    this.id,
    this.uuid,
    this.title,
    this.requirements,
    this.description,
    this.box1,
    this.box2,
    this.notes,
    this.tags = const [],
    this.dateCreated,
    required this.type,
    required this.rarity,
    this.iconFilePath,
    this.relationship,
  });

  CueCard copyWith({
    int? id,
    String? uuid,
    String? title,
    String? requirements,
    String? description,
    String? box1,
    String? box2,
    String? notes,
    List<Tag>? tags,
    DateTime? dateCreated,
    int? type,
    int? rarity,
    String? iconFilePath,
    Relationship? relationship,
  }) {
    return CueCard(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      requirements: requirements ?? this.requirements,
      description: description ?? this.description,
      box1: box1 ?? this.box1,
      box2: box2 ?? this.box2,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      dateCreated: dateCreated ?? this.dateCreated,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      iconFilePath: iconFilePath ?? this.iconFilePath,
      relationship: relationship ?? this.relationship,
    );
  }

  Map<String, Object?> toMapForInsert() {
    return {
      'uuid': (uuid != null && uuid!.isNotEmpty) ? uuid : const Uuid().v4(),
      'title': title,
      'requirements': requirements,
      'description': description,
      'box1': box1,
      'box2': box2,
      'notes': notes,
      'date_created': dateCreated?.toIso8601String(),
      'type': type,
      'rarity': rarity,
      'icon': iconFilePath,
    };
  }

  static CueCard fromMap(Map<String, Object?> map, List<Tag> tags) {
    return CueCard(
      id: map['id'] as int?,
      uuid: map['uuid'] as String?,
      title: map['title'] as String?,
      requirements: map['requirements'] as String?,
      description: map['description'] as String?,
      box1: map['box1'] as String?,
      box2: map['box2'] as String?,
      notes: map['notes'] as String?,
      tags: tags,
      dateCreated: map['date_created'] != null ? DateTime.parse(map['date_created'] as String) : null,
      type: map['type'] as int?,
      rarity: map['rarity'] as int?,
      iconFilePath: map['icon'] as String?,
      relationship: null,
    );
  }

  Map<String, dynamic> toSharedPayload({
    String? typeName,
    int? typeColor,
    String? rarityName,
    int? rarityColor,
  }) {
    return {
      'schema_version': 1,
      'uuid': uuid,
      'title': title,
      'requirements': requirements,
      'description': description,
      'box1': box1,
      'box2': box2,
      'notes': notes,
      'type': type,
      'rarity': rarity,
      'type_name': ?typeName,
      'type_color': ?typeColor,
      'rarity_name': ?rarityName,
      'rarity_color': ?rarityColor,
      'tags': tags.map((t) => t.name).toList(),
      'date_created': dateCreated?.toIso8601String(),
    };
  }

  String canonicalHash({
    String? typeName,
    int? typeColor,
    String? rarityName,
    int? rarityColor,
  }) {
    return computeCanonicalHash(toSharedPayload(
      typeName: typeName,
      typeColor: typeColor,
      rarityName: rarityName,
      rarityColor: rarityColor,
    ));
  }

  @override
  String toString() {
    return 'CueCard{id: $id, uuid: $uuid, title: $title, type: $type, rarity: $rarity, requirements: $requirements, description: $description, box1: $box1, box2: $box2, notes: $notes, tags: $tags, dateCreated: $dateCreated, relationship: $relationship}';
  }
}