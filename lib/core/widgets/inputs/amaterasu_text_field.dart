import 'package:flutter/material.dart';
import '../../theme/Amaterasu_colors.dart';
import '../../theme/Amaterasu_radius.dart';
class AmaterasuTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  const AmaterasuTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      onChanged: onChanged,
      style: const TextStyle(
        color: AmaterasuColors.white,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AmaterasuColors.white54,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(
                prefixIcon,
                color: AmaterasuColors.white54,
              ),
        filled: true,
        fillColor: AmaterasuColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AmaterasuRadius.md,
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AmaterasuRadius.md,
          ),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AmaterasuRadius.md,
          ),
          borderSide: const BorderSide(
            color: AmaterasuColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

