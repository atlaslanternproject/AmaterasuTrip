import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:amaterasutrip/features/auth/providers/auth_controller.dart';
import '../../../../core/widgets/buttons/atlas_discord_button.dart';
import '../../../../core/widgets/buttons/atlas_google_button.dart';
import '../../../../core/widgets/buttons/atlas_primary_button.dart';
import '../../../../core/widgets/cards/atlas_card.dart';
import '../../../../core/widgets/common/atlas_divider.dart';
import '../../../../core/widgets/inputs/atlas_password_field.dart';
import '../../../../core/widgets/inputs/atlas_text_field.dart';
import '../../../../core/storage/remember_me_storage.dart';
class LoginCard extends ConsumerStatefulWidget {
  const LoginCard({super.key});
  @override
  ConsumerState<LoginCard> createState() => _LoginCardState();
}
class _LoginCardState extends ConsumerState<LoginCard> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final resetEmailController = TextEditingController();
  String? loginError;
  bool rememberMe = false;
  bool loading = false;
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    resetEmailController.dispose();
    super.dispose();
  }
  Future<void> login() async {
    if (loading) return;
    setState(() {
      loading = true;
      loginError = null;
    });
    try {
      await RememberMeStorage.save(rememberMe);
      debugPrint(
        "REMEMBER SALVATO: $rememberMe",
      );
      final credential = await ref
          .read(authControllerProvider)
          .loginWithEmailorUsername(
            identifier: emailController.text.trim(),
            password: passwordController.text,
          );
      final user = credential.user;
      await user?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      debugPrint(
        "LOGIN OK: ${refreshedUser?.email}",
      );
      if (!mounted) return;
      if (refreshedUser == null) {
        return;
      }
      if (!refreshedUser.emailVerified) {
        context.go('/verify-email');
      } else {
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        "ERRORE LOGIN: ${e.code}",
      );
      if (!mounted) return;
      setState(() {
        loginError = switch (e.code) {
          'user-not-found' =>
            'Nessun avventuriero trovato con queste credenziali.',
          'wrong-password' =>
            'La parola segreta non apre la porta della taverna.',
          'invalid-email' =>
            'Questa email non sembra valida.',
          _ =>
            'Accesso negato. Riprova.',
        };
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Bentornato',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          AtlasTextField(
            hintText: 'Immettere Email o Username',
            controller: emailController,
            prefixIcon: Icons.person_outline,
            onChanged: (_) {
              setState(() {
                loginError = null;
              });
            },
          ),
          const SizedBox(height: 16),
          AtlasPasswordField(
            hintText: 'Password',
            controller: passwordController,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text(
                        "Recupera password",
                      ),
                      content: TextField(
                        controller: resetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: "Inserisci Email "),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Annulla"),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              await FirebaseAuth.instance.sendPasswordResetEmail(
                                email: resetEmailController.text.trim(),
                              );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("ðŸ“œ Abbiamo inviato una pergamena per recuperare la password.",
                                  ),
                                ),
                              );  
                            } on FirebaseAuthException catch (e) {
                              debugPrint("RESET PASSWORD ERRORE: ${e.code}",
                              );
                            }
                          },
                          child: const Text(
                            "Continua",
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text(
                "Password dimenticata?",
              ),
            ),
          ),
          Row(
            children: [
              Checkbox(
                value: rememberMe,
                onChanged: (value) {
                  setState(() {
                    rememberMe = value ?? false;
                  });
                },
              ),
              const Text(
                'Rimani connesso',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          if (loginError != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                loginError!,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 16),
          AtlasPrimaryButton(
            text: loading
                ? 'Accesso...'
                : 'Accedi',
            onPressed: loading
                ? null
                : login,
          ),
          const SizedBox(height: 20),
          const AtlasDivider(),
          const SizedBox(height: 20),
          AtlasGoogleButton(
            onPressed: () {
              context.go('/google-auth');
            },             
          ),
          const SizedBox(height: 12),
          const AtlasDiscordButton(),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              context.go('/register');
            },
            child: const Text(
              "Non hai un account? Registrati",
            ),
          ),
        ],
      ),
    );
  }
}
