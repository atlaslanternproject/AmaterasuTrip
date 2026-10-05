import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, size: 80),
              const SizedBox(height: 32),
              Text(
                l10n.loginCompleted,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (user != null) ...[
                Text(l10n.name, style: Theme.of(context).textTheme.labelLarge),
                Text(
                  user.displayName ?? l10n.noName,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                Text(l10n.email, style: Theme.of(context).textTheme.labelLarge),
                Text(
                  user.email ?? l10n.noEmail,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
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
