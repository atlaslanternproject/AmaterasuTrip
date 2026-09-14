import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amaterasutrip/features/profile/providers/user_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class CreateUsernamePage extends ConsumerStatefulWidget {
  const CreateUsernamePage({super.key});
  @override
  ConsumerState<CreateUsernamePage> createState() => _CreateUsernamePageState();
}

class _CreateUsernamePageState extends ConsumerState<CreateUsernamePage> {
  final usernameController = TextEditingController();
  String? error;
  bool loading = false;
  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createUsernameTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.createUsernameSubtitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: usernameController,
              onChanged: (_) {
                setState(() {
                  error = null;
                });
              },
              decoration: InputDecoration(
                hintText: l10n.authUsernameHint,
                errorText: error,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() {
                        loading = true;
                        error = null;
                      });
                      final username = usernameController.text.trim();
                      if (username.isEmpty) {
                        setState(() {
                          error = l10n.createUsernameRequired;
                          loading = false;
                        });
                        return;
                      }
                      final user = FirebaseAuth.instance.currentUser;
                      debugPrint("CREATE USERNAME CURRENT USER: ${user?.uid}");
                      if (user == null) {
                        setState(() {
                          error = l10n.createUsernameGoogleUserNotFound;
                          loading = false;
                        });
                        return;
                      }
                      debugPrint('USERNAME CREATO: $username');
                      debugPrint('USER FIREBASE: ${user.uid}');
                      if (!context.mounted) {
                        return;
                      }
                      try {
                        await ref
                            .read(userRepositoryProvider)
                            .createUsername(username: username);

                        if (!mounted) return;
                        setState(() {
                          loading = false;
                        });
                        if (!context.mounted) return;
                        context.go('/home');
                      } on FirebaseAuthException catch (e) {
                        if (!mounted) return;
                        setState(() {
                          loading = false;
                          error = switch (e.code) {
                            'username-already-in-use' =>
                              l10n.createUsernameAlreadyTaken,
                            _ => l10n.createUsernameGoogleUserNotFound,
                          };
                        });
                      } catch (e) {
                        debugPrint('CREATE USERNAME ERRORE: $e');
                        if (!mounted) return;
                        setState(() {
                          loading = false;
                          error = l10n.createUsernameGoogleUserNotFound;
                        });
                      }
                    },
              child: Text(l10n.createUsernameContinue),
            ),
          ],
        ),
      ),
    );
  }
}
