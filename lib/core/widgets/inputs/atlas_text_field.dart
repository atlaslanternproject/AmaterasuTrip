import 'package:flutter/material.dart';
import '../../theme/atlas_colors.dart';
import '../../theme/atlas_radius.dart';
class AtlasTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  const AtlasTextField({
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
        color: AtlasColors.white,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AtlasColors.white54,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(
                prefixIcon,
                color: AtlasColors.white54,
              ),
        filled: true,
        fillColor: AtlasColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AtlasRadius.md,
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AtlasRadius.md,
          ),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AtlasRadius.md,
          ),
          borderSide: const BorderSide(
            color: AtlasColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
