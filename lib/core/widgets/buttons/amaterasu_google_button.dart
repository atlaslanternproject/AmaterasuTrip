// Bottone "Accedi con Google" nello stile dell'app.

import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'amaterasu_primary_button.dart';

class AmaterasuGoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const AmaterasuGoogleButton({super.key, this.onPressed});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmaterasuPrimaryButton(
      text: l10n.commonGoogleSignIn,
      icon: Image.asset('assets/icons/google.png', width: 22, height: 22),
      onPressed: onPressed,
    );
  }
}
