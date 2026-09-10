import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amaterasutrip/features/profile/providers/user_provider.dart';
class CreateUsernamePage extends ConsumerStatefulWidget {
  const CreateUsernamePage({
    super.key,
  });
  @override
  ConsumerState<CreateUsernamePage> createState() =>
      _CreateUsernamePageState();
}
class _CreateUsernamePageState
    extends ConsumerState<CreateUsernamePage> {
  final usernameController =
      TextEditingController();
  String? error;
  bool loading = false;
  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crea Username',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Text(
              'Scegli il tuo nome avventuriero',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller:
                  usernameController,
                  onChanged: (_) {
                    setState(() {
                      error = null;
                    });
                  },
              decoration: InputDecoration(
                hintText:
                    'Username',
                errorText:
                    error,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              child:
                  const Text(
                    'Continua',
                  ),
              onPressed: () async {
                setState(() {
                 loading = true;
                 error = null; 
                });
                final username =
                    usernameController.text.trim();
                if (username.isEmpty) {
                  setState(() {
                    error =
                        'Inserisci un username';
                        loading = false;
                  });
                  return;
                }
                final user = FirebaseAuth.instance.currentUser;
                debugPrint(
                  "CREATE USERNAME CURRENT USER:${user?.uid}",
                );
                if (user == null) {
                  setState(() {
                    error = 'Utente Google non trovato. Riprova';
                    loading = false;
                  });
                  return;
                }
                debugPrint(
                  'USERNAME CREATO: $username',
                );
                debugPrint(
                  'USER FIREBASE: ${user.uid}',
                );
                if (!context.mounted) {
                  return;
                }
              try {
                await ref
                    .read(userRepositoryProvider)
                    .createUsername(
                      username: username,
                    );
                setState(() {
                  loading = false;
                });
                if (!context.mounted) return;
                context.go('/home');
              } catch (e) {
                setState(() {
                  if (e.toString().contains(
                    'Username giÃ  in uso',
                  )) {
                    error =
                      'Questo username Ã¨ giÃ  in uso. Scegline un altro.';
                  } else {
                      error = e.toString();
                  }
                });
              }
              },
            ),
          ],
        ),
      ),
    );
  }
}
