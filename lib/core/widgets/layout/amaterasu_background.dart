import 'package:flutter/material.dart';
import '../../theme/Amaterasu_colors.dart';
class AmaterasuBackground extends StatelessWidget {
  final Widget child;
  const AmaterasuBackground({
    super.key,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AmaterasuColors.background,
            AmaterasuColors.backgroundSecondary,
            AmaterasuColors.background,
          ],
        ),
      ),
      child: child,
    );
  }
}

