import 'package:flutter/material.dart';
import '../../theme/Amaterasu_colors.dart';
import '../../theme/Amaterasu_radius.dart';
class AmaterasuPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  const AmaterasuPasswordField({
    super.key,
    this.controller,
    this.hintText = "Password",
  });
  @override
  State<AmaterasuPasswordField> createState() =>
      _AmaterasuPasswordFieldState();
}
class _AmaterasuPasswordFieldState
    extends State<AmaterasuPasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      style: const TextStyle(
        color: AmaterasuColors.white,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          color: AmaterasuColors.white54,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: AmaterasuColors.white54,
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

            color: AmaterasuColors.white54,
          ),
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

