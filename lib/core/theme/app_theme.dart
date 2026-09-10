import 'package:flutter/material.dart';
import 'atlas_colors.dart';
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AtlasColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AtlasColors.primary,
    brightness: Brightness.dark,
  ),
);
