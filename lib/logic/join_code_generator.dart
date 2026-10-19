import 'dart:math';

/// Generates unambiguous, human-friendly alphanumeric join codes for campaigns.
///
/// Excludes confusing characters:
/// - 0 and O
/// - 1, I, and L
class JoinCodeGenerator {
  static const String alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  /// Generates a single join code of specified length (default 6).
  static String generate([int length = 6, Random? random]) {
    assert(length >= 4 && length <= 16, 'Join code length should be between 4 and 16');
    final rng = random ?? Random.secure();
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(alphabet[rng.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }

  /// Generates a unique join code with retry on collision against an asynchronous checker.
  static Future<String> generateUnique(
    Future<bool> Function(String code) isCodeTaken, {
    int length = 6,
    int maxRetries = 10,
    Random? random,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final code = generate(length, random);
      final taken = await isCodeTaken(code);
      if (!taken) {
        return code;
      }
    }
    // If collision persists, try with a slightly longer code
    return generate(length + 1, random);
  }
}
