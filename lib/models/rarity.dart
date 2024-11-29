import 'package:dnd_cuecard_app/interfaces/nameable.dart';
import 'package:flutter/painting.dart';

class Rarity implements Nameable {
  final int? id;
  @override
  final String name;
  final Color color;

  const Rarity({
    this.id,
    required this.name,
    required this.color,
  });

  Map<String, Object?> toMapForInsert() {
    return {
      'name': name,
      'color': color.value,
    };
  }
}