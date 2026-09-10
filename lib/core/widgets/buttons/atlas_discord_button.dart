import 'package:flutter/material.dart';
import 'atlas_primary_button.dart';
class AtlasDiscordButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const AtlasDiscordButton({
    super.key,
    this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return AtlasPrimaryButton(
      text: "Accedi con Discord",
      icon: Image.asset(
        'assets/icons/discord.png',
        width: 22,
        height: 22,
      ),
      onPressed: onPressed,
    );
  }
}
