// Tema Material 3 scuro dell'app, costruito dal colore primario.

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
