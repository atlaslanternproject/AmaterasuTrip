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
import '../../../../l10n/app_localizations.dart';

class RegisterCard extends ConsumerStatefulWidget {
  const RegisterCard({super.key});
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
    final l10n = AppLocalizations.of(context)!;
    return AmaterasuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.authCreateAccount,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          AmaterasuTextField(
            hintText: l10n.authUsernameHint,
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
            hintText: l10n.authEmailHint,
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
            hintText: l10n.authPasswordHint,
            controller: passwordController,
          ),
          const SizedBox(height: 16),
          AmaterasuPasswordField(
            hintText: l10n.authConfirmPasswordHint,
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
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          AmaterasuPrimaryButton(
            text: l10n.authRegister,
            onPressed: () async {
              setState(() {
                registerError = null;
              });
              if (usernameController.text.trim().isEmpty ||
                  emailController.text.trim().isEmpty ||
                  passwordController.text.isEmpty ||
                  confirmPasswordController.text.isEmpty) {
                setState(() {
                  registerError = l10n.authRegisterFillFields;
                });
                return;
              }
              if (passwordController.text != confirmPasswordController.text) {
                setState(() {
                  registerError = l10n.authRegisterPasswordsMismatch;
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
                debugPrint("ERRORE REGISTER: ${e.code}");
                if (!context.mounted) return;
                setState(() {
                  registerError = switch (e.code) {
                    'email-already-in-use' =>
                      l10n.authRegisterEmailAlreadyInUse,
                    'weak-password' => l10n.authRegisterWeakPassword,
                    'invalid-email' => l10n.authRegisterInvalidEmail,
                    _ => l10n.authRegisterGenericError,
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
          AmaterasuDiscordButton(onPressed: () {}),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              context.go('/');
            },
            child: Text(l10n.authAlreadyHaveAccountSignIn),
          ),
        ],
      ),
    );
  }
}
