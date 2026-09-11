import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/layout/Amaterasu_background.dart';
import '../../../../core/widgets/layout/Amaterasu_hero.dart';
import '../../../../core/widgets/buttons/Amaterasu_primary_button.dart';
import '../../../../l10n/app_localizations.dart';
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({
    super.key,
  });
  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}
class _VerifyEmailPageState extends State<VerifyEmailPage> {
  String? verifyError;
  Future<void> checkVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    await user.reload();
    final updatedUser =
        FirebaseAuth.instance.currentUser;
    if (updatedUser?.emailVerified ?? false) {
      debugPrint(
        "EMAIL VERIFICATA",
      );
      if (!mounted) return;
      context.go('/');
    } else {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        verifyError =
            l10n.authVerifyEmailNotVerified;
      });
    }
  }
  Future<void> resendEmail() async {
    final user =
        FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    await user.sendEmailVerification();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      verifyError =
          l10n.authVerifyEmailSent;
    });
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: AmaterasuBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const AmaterasuHero(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1E26),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.mark_email_read_outlined,
                          color: Colors.amber,
                          size: 72,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.authVerifyEmailTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.authVerifyEmailDescription,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (verifyError != null) ...[
                          Container(
                            padding:
                                const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    Colors.redAccent.withValues(
                                  alpha: 0.40,
                                ),
                              ),
                            ),
                            child: Text(
                              verifyError!,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        AmaterasuPrimaryButton(
                          text:
                              l10n.authVerifyEmailConfirmed,
                          onPressed: checkVerification,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: resendEmail,
                          child: Text(
                            l10n.authVerifyEmailResend,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}