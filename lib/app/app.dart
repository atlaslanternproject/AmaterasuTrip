import 'package:flutter/material.dart';
import 'router.dart';
import '../core/theme/app_theme.dart';
class AmaterasuTripApp extends StatelessWidget {
  const AmaterasuTripApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AmaterasuTrip',
      theme: appTheme,
      routerConfig: amaterasuRouter,
    );
  }
}


