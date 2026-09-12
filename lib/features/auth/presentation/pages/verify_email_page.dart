import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/layout/Amaterasu_background.dart';
import '../../../../core/widgets/layout/Amaterasu_hero.dart';
import '../../../../core/widgets/auth/amaterasu_email_verification_card.dart';
import '../../../../l10n/app_localizations.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});
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
    final updatedUser = FirebaseAuth.instance.currentUser;
    if (updatedUser?.emailVerified ?? false) {
      debugPrint("EMAIL VERIFICATA");
      if (!mounted) return;
      context.go('/');
    } else {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        verifyError = l10n.authVerifyEmailNotVerified;
      });
    }
  }

  Future<void> resendEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    await user.sendEmailVerification();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      verifyError = l10n.authVerifyEmailSent;
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AmaterasuEmailVerificationCard(
                    title: l10n.authVerifyEmailTitle,
                    description: l10n.authVerifyEmailDescription,
                    confirmedText: l10n.authVerifyEmailConfirmed,
                    resendText: l10n.authVerifyEmailResend,
                    message: verifyError,
                    onConfirmed: checkVerification,
                    onResend: resendEmail,
                    compact: true,
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
