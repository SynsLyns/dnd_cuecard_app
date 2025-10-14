class Tag {
  final int? id;
  final String name;

  Tag({
    this.id,
    required this.name,
  });

  Map<String, Object?> toMapForInsert() {
    return {
      'name': name,
    };
  }

  static Tag fromMap(Map<String, Object?> map) {
    return Tag(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }

  @override
  String toString() {
    return 'Tag{id: $id, name: $name}';
  }
}