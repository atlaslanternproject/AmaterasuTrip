import 'package:flutter/material.dart';

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

  static const Color _surfaceColor = Color(0xFF1A1715);
  static const Color _borderColor = Color(0xFF332824);
  static const Color _creamColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);
  static const Color _accentColor = Color(0xFFD96C32);

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
