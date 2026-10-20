import 'dart:typed_data';

class PlayerSharedCard {
  final String id;
  final int version;
  final int schemaVersion;
  final Map<String, dynamic> payload;
  final Uint8List? iconBytes;

  const PlayerSharedCard({
    required this.id,
    required this.version,
    required this.schemaVersion,
    required this.payload,
    this.iconBytes,
  });

  factory PlayerSharedCard.fromMap(Map<String, dynamic> map) {
    final rawPayload = map['payload'];
    return PlayerSharedCard(
      id: map['id']?.toString() ?? '',
      version: _intValue(map['version']) ?? 1,
      schemaVersion: _intValue(map['schema_version']) ?? 1,
      payload: rawPayload is Map
          ? rawPayload.map((key, value) => MapEntry(key.toString(), value))
          : const {},
      iconBytes: map['icon_bytes'] is Uint8List
          ? map['icon_bytes'] as Uint8List
          : null,
    );
  }

  String get title => _stringValue(payload['title']) ?? 'Untitled card';
  String? get requirements => _stringValue(payload['requirements']);
  String? get description => _stringValue(payload['description']);
  String? get notes => _stringValue(payload['notes']);
  String? get box1 => _stringValue(payload['box1']);
  String? get box2 => _stringValue(payload['box2']);
  String? get typeName => _stringValue(payload['type_name']);
  String? get rarityName => _stringValue(payload['rarity_name']);
  int? get typeColor => _intValue(payload['type_color']);
  int? get rarityColor => _intValue(payload['rarity_color']);

  List<String> get tags {
    final value = payload['tags'];
    if (value is! List) return const [];
    return value.map(_stringValue).whereType<String>().toList();
  }

  static String? _stringValue(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  static int? _intValue(Object? value, {int? fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}
