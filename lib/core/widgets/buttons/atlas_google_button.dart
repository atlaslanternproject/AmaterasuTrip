import 'package:flutter/material.dart';
import 'atlas_primary_button.dart';
class AtlasGoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const AtlasGoogleButton({
    super.key,
    this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return AtlasPrimaryButton(
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
