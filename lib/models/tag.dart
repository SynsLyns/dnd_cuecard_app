import 'package:dnd_cuecard_app/interfaces/nameable.dart';

class Tag implements Nameable {
  @override
  final int? id;
  @override
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