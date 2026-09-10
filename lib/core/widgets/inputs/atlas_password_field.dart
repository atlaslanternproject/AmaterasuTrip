import 'package:flutter/material.dart';
import '../../theme/atlas_colors.dart';
import '../../theme/atlas_radius.dart';
class AtlasPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  const AtlasPasswordField({
    super.key,
    this.controller,
    this.hintText = "Password",
  });
  @override
  State<AtlasPasswordField> createState() =>
      _AtlasPasswordFieldState();
}
class _AtlasPasswordFieldState
    extends State<AtlasPasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      style: const TextStyle(
        color: AtlasColors.white,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          color: AtlasColors.white54,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: AtlasColors.white54,
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscure = !_obscure;
            });
          },
          icon: Icon(
            _obscure
                ? Icons.visibility_off
                : Icons.visibility,

            color: AtlasColors.white54,
          ),
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
