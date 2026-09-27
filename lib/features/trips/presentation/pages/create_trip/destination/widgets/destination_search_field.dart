import 'package:flutter/material.dart';

class DestinationSearchField extends StatelessWidget {
  const DestinationSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  static const Color _surfaceColor = Color(0xFF1A1715);
  static const Color _borderColor = Color(0xFF3A2A24);
  static const Color _creamColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);
  static const Color _accentColor = Color(0xFFD95C32);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: _creamColor,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: _accentColor,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: _secondaryTextColor.withValues(alpha: 0.62),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _secondaryTextColor,
          size: 23,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: _secondaryTextColor,
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: _surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _accentColor, width: 1.2),
        ),
      ),
    );
  }
}
