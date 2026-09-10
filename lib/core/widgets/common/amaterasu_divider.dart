import 'package:flutter/material.dart';
import '../../theme/Amaterasu_colors.dart';
class AmaterasuDivider extends StatelessWidget {
  final String text;
  const AmaterasuDivider({
    super.key,
    this.text = "oppure",
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AmaterasuColors.border,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AmaterasuColors.white54,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: AmaterasuColors.border,
          ),
        ),
      ],
    );
  }
}

