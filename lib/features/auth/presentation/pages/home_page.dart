import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('AmaterasuTrip'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, size: 80),
              const SizedBox(height: 32),
              const Text(
                'Login completato!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (user != null) ...[
                Text('Nome:', style: Theme.of(context).textTheme.labelLarge),
                Text(
                  user.displayName ?? 'Nessun nome',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                Text('Email:', style: Theme.of(context).textTheme.labelLarge),
                Text(
                  user.email ?? 'Nessuna email',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                Text('UID:', style: Theme.of(context).textTheme.labelLarge),
                SelectableText(user.uid, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout test'),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pop();
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
