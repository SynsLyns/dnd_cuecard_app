import 'package:dnd_cuecard_app/interfaces/categorizable.dart';
import 'package:flutter/painting.dart';

class CardType implements Categorizable {
  @override
  final int? id;
  @override
  final String name;
  @override
  final Color color;

  const CardType({
    this.id,
    required this.name,
    required this.color,
  });

  Map<String, Object?> toMapForInsert() {
    return {
      'name': name,
      'color': color.toARGB32(),
    };
  }

  static CardType fromMap(Map<String, Object?> map) {
    return CardType(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: Color(map['color'] as int),
    );
  }
}