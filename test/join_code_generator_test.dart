import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dnd_cuecard_app/logic/join_code_generator.dart';

void main() {
  group('JoinCodeGenerator Tests', () {
    test('generates code of default length 6 with unambiguous characters', () {
      final code = JoinCodeGenerator.generate();
      expect(code.length, equals(6));
      expect(RegExp(r'^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]+$').hasMatch(code), isTrue);

      // Verify no ambiguous characters
      expect(code.contains('0'), isFalse);
      expect(code.contains('O'), isFalse);
      expect(code.contains('1'), isFalse);
      expect(code.contains('I'), isFalse);
      expect(code.contains('L'), isFalse);
    });

    test('generates requested custom length', () {
      final code8 = JoinCodeGenerator.generate(8);
      expect(code8.length, equals(8));
    });

    test('retries on collision when generating unique code', () async {
      int checkCount = 0;
      final existingCodes = {'ABCDEF', 'GHIJKL'};

      final code = await JoinCodeGenerator.generateUnique(
        (candidate) async {
          checkCount++;
          if (checkCount <= 2) {
            return true; // Simulate collision on first 2 attempts
          }
          return existingCodes.contains(candidate);
        },
        random: Random(42),
      );

      expect(checkCount, greaterThanOrEqualTo(3));
      expect(code.length, equals(6));
      expect(existingCodes.contains(code), isFalse);
    });
  });
}
