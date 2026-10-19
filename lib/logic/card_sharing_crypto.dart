import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Recursively canonicalizes a JSON map so that:
/// - Map keys are sorted alphabetically.
/// - The 'tags' list (if present) is sorted alphabetically.
Map<String, dynamic> canonicalizePayload(Map<String, dynamic> payload) {
  final sorted = <String, dynamic>{};
  final keys = payload.keys.toList()..sort();

  for (final key in keys) {
    final value = payload[key];
    if (key == 'tags' && value is List) {
      final tagsList = List<String>.from(value.map((e) => e.toString()))..sort();
      sorted[key] = tagsList;
    } else if (value is Map<String, dynamic>) {
      sorted[key] = canonicalizePayload(value);
    } else {
      sorted[key] = value;
    }
  }
  return sorted;
}

/// Computes a canonical SHA-256 hash of a payload map.
/// The same logical card content always produces the identical hex hash.
String computeCanonicalHash(Map<String, dynamic> payload) {
  final canonical = canonicalizePayload(payload);
  final jsonString = jsonEncode(canonical);
  final bytes = utf8.encode(jsonString);
  return sha256.convert(bytes).toString();
}
