import 'package:dnd_cuecard_app/theme/app_colors.dart';
import 'package:dnd_cuecard_app/theme/contrast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrastRatio(Color foreground, Color background) {
  final first = foreground.computeLuminance() + 0.05;
  final second = background.computeLuminance() + 0.05;
  return first > second ? first / second : second / first;
}

void main() {
  group('readableOn', () {
    test('uses the light theme text color on a dark green background', () {
      expect(readableOn(const Color(0xFF17331F)), AppColors.ground);
    });

    test('uses the dark theme text color on a pale cream background', () {
      expect(readableOn(const Color(0xFFF1E8D5)), AppColors.ink);
    });

    test(
      'chooses the text color with the higher contrast on mid-tone orange',
      () {
        const orange = Color(0xFFC87532);
        final selected = readableOn(orange);

        expect(selected, anyOf(AppColors.ground, AppColors.ink));
        expect(
          _contrastRatio(orange, selected),
          greaterThanOrEqualTo(
            _contrastRatio(
              orange,
              selected == AppColors.ground ? AppColors.ink : AppColors.ground,
            ),
          ),
        );
      },
    );
  });
}
