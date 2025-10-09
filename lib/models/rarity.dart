import 'package:dnd_cuecard_app/interfaces/categorizable.dart';
import 'package:flutter/painting.dart';

class Rarity implements Categorizable {
  @override
  final int? id;
  @override
  final String name;
  @override
  final Color color;

  const Rarity({
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