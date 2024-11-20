import '../enums/card_type.dart';
import '../enums/rarity.dart';

class CueCard {
  final int? id;
  final String title;
  final String requirements;
  final String description;
  final String box1;
  final String box2;
  final String? notes;
  final List<String> tags;
  final DateTime? dateCreated;
  final CardType type;
  final Rarity rarity;
  final String? iconFilePath;

  CueCard({
    this.id,
    required this.title,
    required this.requirements,
    required this.description,
    required this.box1,
    required this.box2,
    this.notes,
    this.tags = const [],
    this.dateCreated,
    required this.type,
    required this.rarity,
    this.iconFilePath,
  });

  Map<String, Object?> toMapForInsert() {
    return {
      'title': title,
      'requirements': requirements,
      'description': description,
      'box1': box1,
      'box2': box2,
      'notes': notes,
      'dateCreated': dateCreated?.toIso8601String(),
      'type': type.name,
      'rarity': rarity.name,
      'icon': iconFilePath,
    };
  }

  @override
  String toString() {
    return 'CueCard{id: $id, title: $title, type: $type, rarity: $rarity, requirements: $requirements, description: $description, box1: $box1, box2: $box2, notes: $notes, tags: $tags, dateCreated: $dateCreated}';
  }
}