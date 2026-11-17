// Pagina Home: per ora mostra i dati dell'utente collegato
// (nome, email) e un logout di prova.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AmaterasuSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, size: 80),
              const SizedBox(height: AmaterasuSpacing.xl),
              Text(
                l10n.loginCompleted,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AmaterasuSpacing.lg),
              if (user != null) ...[
                Text(l10n.name, style: Theme.of(context).textTheme.labelLarge),
                Text(
                  user.displayName ?? l10n.noName,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: AmaterasuSpacing.md),
                Text(l10n.email, style: Theme.of(context).textTheme.labelLarge),
                Text(
                  user.email ?? l10n.noEmail,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: AmaterasuSpacing.md),
                Text(l10n.uid, style: Theme.of(context).textTheme.labelLarge),
                SelectableText(user.uid, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: Text(l10n.logoutTest),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();

                  if (context.mounted) {
                    context.go('/');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
