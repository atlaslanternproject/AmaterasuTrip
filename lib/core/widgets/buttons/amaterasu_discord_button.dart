import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'Amaterasu_primary_button.dart';

class AmaterasuDiscordButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const AmaterasuDiscordButton({super.key, this.onPressed});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmaterasuPrimaryButton(
      text: l10n.commonDiscordSignIn,
      icon: Image.asset('assets/icons/discord.png', width: 22, height: 22),
      onPressed: onPressed,
    );
  }
}
