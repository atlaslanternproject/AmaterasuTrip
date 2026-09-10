import 'package:flutter/material.dart';
import 'Amaterasu_primary_button.dart';
class AmaterasuGoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const AmaterasuGoogleButton({
    super.key,
    this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return AmaterasuPrimaryButton(
      text: "Accedi con Google",
      icon: Image.asset(
        'assets/icons/google.png',
        width: 22,
        height: 22,
      ),
      onPressed: onPressed,
    );
  }
}

