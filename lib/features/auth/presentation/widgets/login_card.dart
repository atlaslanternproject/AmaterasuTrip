import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:amaterasutrip/features/auth/providers/auth_controller.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../../../../core/widgets/buttons/Amaterasu_discord_button.dart';
import '../../../../core/widgets/buttons/Amaterasu_google_button.dart';
import '../../../../core/widgets/buttons/Amaterasu_primary_button.dart';
import '../../../../core/widgets/cards/Amaterasu_card.dart';
import '../../../../core/widgets/common/Amaterasu_divider.dart';
import '../../../../core/widgets/inputs/Amaterasu_password_field.dart';
import '../../../../core/widgets/inputs/Amaterasu_text_field.dart';
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
      debugPrint("LOGIN: inizio");
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
        loginError = e.code;
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }
  String getLoginErrorMessage(
    AppLocalizations l10n,
    String errorCode,
  ) {
    return switch (errorCode) {
      'user-not-found' => l10n.authLoginErrorUserNotFound,
      'wrong-password' => l10n.authLoginErrorWrongPassword,
      'invalid-email' => l10n.authLoginErrorInvalidEmail,
      _ => l10n.authLoginErrorGeneric,
    };
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmaterasuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.authWelcomeBack,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          AmaterasuTextField(
            hintText: l10n.authEmailOrUsernameHint,
            controller: emailController,
            prefixIcon: Icons.person_outline,
            onChanged: (_) {
              setState(() {
                loginError = null;
              });
            },
          ),
          const SizedBox(height: 16),
          AmaterasuPasswordField(
            hintText: l10n.authPasswordHint,
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
                      title: Text(
                        l10n.authForgotPassword,
                      ),
                      content: TextField(
                        controller: resetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: l10n.authInsertEmail,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            l10n.authCancel,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              await FirebaseAuth.instance
                                  .sendPasswordResetEmail(
                                email: resetEmailController.text.trim(),
                              );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.authPasswordResetEmailSent,
                                  ),
                                ),
                              );
                            } on FirebaseAuthException catch (e) {
                              debugPrint(
                                "RESET PASSWORD ERRORE: ${e.code}",
                              );
                            }
                          },
                          child: Text(
                            l10n.authContinue,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text(
                l10n.authForgotPasswordQuestion,
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
              Text(
                l10n.authStaySignedIn,
                style: const TextStyle(
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
                getLoginErrorMessage(
                  l10n,
                  loginError!,
                ),
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 16),
          AmaterasuPrimaryButton(
            text: loading
                ? l10n.authSigningIn
                : l10n.authSignIn,
            onPressed: loading
                ? null
                : login,
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
          const AmaterasuDiscordButton(),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              context.go('/register');
            },
            child: Text(
              l10n.authNoAccountRegister,
            ),
          ),
        ],
      ),
    );
  }
}