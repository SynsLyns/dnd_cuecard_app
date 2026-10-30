import 'package:flutter/material.dart';

import 'app_colors.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance() + 0.05;
  final lb = b.computeLuminance() + 0.05;
  return la > lb ? la / lb : lb / la;
}

Color readableOn(Color bg) =>
    _ratio(bg, AppColors.ground) >= _ratio(bg, AppColors.ink)
    ? AppColors.ground
    : AppColors.ink;
