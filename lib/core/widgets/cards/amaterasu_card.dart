import 'package:flutter/material.dart';
import '../../theme/Amaterasu_colors.dart';
import '../../theme/Amaterasu_radius.dart';
import '../../theme/Amaterasu_spacing.dart';
class AmaterasuCard extends StatelessWidget {
  final Widget child;
  const AmaterasuCard({
    super.key,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      padding: const EdgeInsets.all(
        AmaterasuSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AmaterasuColors.card,
        borderRadius: BorderRadius.circular(
          AmaterasuRadius.lg,
        ),
        border: Border.all(
          color: AmaterasuColors.border,
        ),
      ),
      child: child,
    );
  }
}

