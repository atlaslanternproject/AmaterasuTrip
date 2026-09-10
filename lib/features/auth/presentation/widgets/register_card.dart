import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:amaterasutrip/features/auth/providers/auth_controller.dart';
import '../../../../core/widgets/buttons/Amaterasu_discord_button.dart';
import '../../../../core/widgets/buttons/Amaterasu_google_button.dart';
import '../../../../core/widgets/buttons/Amaterasu_primary_button.dart';
import '../../../../core/widgets/cards/Amaterasu_card.dart';
import '../../../../core/widgets/common/Amaterasu_divider.dart';
import '../../../../core/widgets/inputs/Amaterasu_password_field.dart';
import '../../../../core/widgets/inputs/Amaterasu_text_field.dart';
class RegisterCard extends ConsumerStatefulWidget {
  const RegisterCard({
    super.key,
  });
  @override
  ConsumerState<RegisterCard> createState() => _RegisterCardState();
}
class _RegisterCardState extends ConsumerState<RegisterCard> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String? registerError;
  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AmaterasuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Crea il tuo account",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          AmaterasuTextField(
            hintText: "Username",
            controller: usernameController,
            prefixIcon: Icons.person_outline,
            onChanged: (_) {
              setState(() {
                registerError = null;
              });
            },
          ),
          const SizedBox(height: 16),
          AmaterasuTextField(
            hintText: "Email",
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            onChanged: (_) {
              setState(() {
                registerError = null;
              });
            },
          ),
          const SizedBox(height: 16),
          AmaterasuPasswordField(
            hintText: "Password",
            controller: passwordController,
          ),
          const SizedBox(height: 16),
          AmaterasuPasswordField(
           hintText: "Conferma password",
            controller: confirmPasswordController,
          ),
          const SizedBox(height: 8),
          if (registerError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.40),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      registerError!,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          AmaterasuPrimaryButton(
            text: "Registrati",
            onPressed: () async {
              setState(() {
                registerError = null;
              });
              if (usernameController.text.trim().isEmpty ||
                  emailController.text.trim().isEmpty ||
                  passwordController.text.isEmpty ||
                  confirmPasswordController.text.isEmpty) {
                setState(() {
                  registerError =
                      "âš ï¸ Compila tutti i campi richiesti.";
                });
                return;
              }
              if (passwordController.text !=
                  confirmPasswordController.text) {
                setState(() {
                  registerError =
                      "âš ï¸ Le due parole segrete non coincidono.";
                });
                return;
              }
              try {
                await ref
                    .read(authControllerProvider)
                    .register(
                      username: usernameController.text.trim(),
                      email: emailController.text.trim(),
                      password: passwordController.text,
                    );
                debugPrint("REGISTER OK");
                if (!context.mounted) return;
                context.go('/verify-email');
              } on FirebaseAuthException catch (e) {
                debugPrint(
                  "ERRORE REGISTER: ${e.code}",
                );
                if (!context.mounted) return;
                setState(() {
                  registerError = switch (e.code) {
                    'email-already-in-use' =>
                      "âš ï¸ Un avventuriero Ã¨ giÃ  registrato con questa pergamena.",
                    'weak-password' =>
                      "âš ï¸ La parola segreta Ã¨ troppo debole.",
                    'invalid-email' =>
                      "âš ï¸ Il corvo non riesce a raggiungere questo indirizzo.",
                    _ =>
                      "âš ï¸ Impossibile completare la registrazione.",
                  };
                });
              }
            },
          ),
          const SizedBox(height: 20),
          const AmaterasuDivider(),
          const SizedBox(height: 20),
          AmaterasuGoogleButton(
            onPressed: () {
              context.go('/google-auth');
            },
          ),
          const SizedBox(height: 12),
          AmaterasuDiscordButton(
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              context.go('/');
            },
            child: const Text(
              "Hai giÃ  un account? Accedi",
            ),
          ),
        ],
      ),
    );
  }
}

