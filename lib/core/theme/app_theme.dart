import 'package:flutter/material.dart';
import 'amaterasu_colors.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AmaterasuColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AmaterasuColors.primary,
    brightness: Brightness.dark,
  ),
);
