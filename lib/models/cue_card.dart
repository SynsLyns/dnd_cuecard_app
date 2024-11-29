class CueCard {
  final int? id;
  final String? title;
  final String? requirements;
  final String? description;
  final String? box1;
  final String? box2;
  final String? notes;
  final List<String> tags;
  final DateTime? dateCreated;
  final int? type;
  final int? rarity;
  final String? iconFilePath;

  CueCard({
    this.id,
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
  });

  Map<String, Object?> toMapForInsert() {
    return {
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

  static CueCard fromMap(Map<String, Object?> map) {
    return CueCard(
      id: map['id'] as int?,
      title: map['title'] as String?,
      requirements: map['requirements'] as String?,
      description: map['description'] as String?,
      box1: map['box1'] as String?,
      box2: map['box2'] as String?,
      notes: map['notes'] as String?,
      dateCreated: map['date_created'] != null ? DateTime.parse(map['date_created'] as String) : null,
      type: map['type'] as int?,
      rarity: map['rarity'] as int?,
      iconFilePath: map['icon'] as String?,
    );
  }

  @override
  String toString() {
    return 'CueCard{id: $id, title: $title, type: $type, rarity: $rarity, requirements: $requirements, description: $description, box1: $box1, box2: $box2, notes: $notes, tags: $tags, dateCreated: $dateCreated}';
  }
}