import 'package:dnd_cuecard_app/interfaces/nameable.dart';
import 'package:flutter/painting.dart';

class CardType implements Nameable {
  final int? id;
  @override
  final String name;
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
}