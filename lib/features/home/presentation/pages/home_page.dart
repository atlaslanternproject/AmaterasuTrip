// Home page temporanea
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AtlasLantern'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Login completato!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              user?.displayName ?? 'Utente Google',
            ),
            Text(
              user?.email ?? '',
            ),
            const SizedBox(height: 20),
            SelectableText(
              user?.uid ?? 'No UID',
            ),
          ],
        ),
      ),
    );
  }
}
