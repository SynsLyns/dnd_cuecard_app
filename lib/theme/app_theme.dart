import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({required this.fraunces});

  final TextStyle fraunces;

  @override
  AppTypography copyWith({TextStyle? fraunces}) =>
      AppTypography(fraunces: fraunces ?? this.fraunces);

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return AppTypography(
      fraunces: TextStyle.lerp(fraunces, other.fraunces, t)!,
    );
  }
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.matcha,
      brightness: Brightness.light,
      primary: AppColors.matcha,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
    );
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ground,
      fontFamily: 'DMSans',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.ink, fontSize: 15),
        bodyMedium: TextStyle(color: AppColors.ink, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.muted, fontSize: 13),
        titleLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: TextStyle(
          color: AppColors.matcha,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      extensions: const [
        AppTypography(
          fraunces: TextStyle(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      dividerColor: AppColors.hairline,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: outline,
        enabledBorder: outline,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.matcha, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: const TextStyle(color: AppColors.muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.matcha,
          foregroundColor: AppColors.ground,
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.matcha,
          minimumSize: const Size(44, 44),
          side: const BorderSide(color: AppColors.border),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.paper),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.matcha
              : AppColors.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sage,
        side: BorderSide.none,
        labelStyle: const TextStyle(
          color: AppColors.matcha,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      cardTheme: CardThemeData(
        color: AppColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
