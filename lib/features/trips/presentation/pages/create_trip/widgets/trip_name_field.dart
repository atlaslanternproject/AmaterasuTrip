// Campo del nome del viaggio.

import 'package:flutter/material.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

class TripNameField extends StatelessWidget {
  const TripNameField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  static const Color _surfaceColor = AmaterasuColors.surfaceNeutral;
  static const Color _borderColor = AmaterasuColors.surfaceHigh;
  static const Color _creamColor = AmaterasuColors.textPrimary;
  static const Color _secondaryTextColor = AmaterasuColors.textSecondary;
  static const Color _accentColor = AmaterasuColors.accentBudget;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _borderColor),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          const Icon(Icons.luggage_outlined, color: _creamColor, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              cursorColor: _accentColor,
              style: const TextStyle(
                color: _creamColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                labelText: label,
                labelStyle: const TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 14,
                ),
                hintText: hint,
                hintStyle: TextStyle(
                  color: _secondaryTextColor.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: controller.clear,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.cancel_rounded,
                color: _secondaryTextColor,
                size: 19,
              ),
            ),
        ],
      ),
    );
  }
}
