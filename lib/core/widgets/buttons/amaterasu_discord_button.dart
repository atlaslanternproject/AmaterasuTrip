import 'package:flutter/material.dart';
import 'Amaterasu_primary_button.dart';
class AmaterasuDiscordButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const AmaterasuDiscordButton({
    super.key,
    this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return AmaterasuPrimaryButton(
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

