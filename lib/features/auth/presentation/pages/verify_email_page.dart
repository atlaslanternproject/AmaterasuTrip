import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/layout/atlas_background.dart';
import '../../../../core/widgets/layout/atlas_hero.dart';
import '../../../../core/widgets/buttons/atlas_primary_button.dart';
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({
    super.key,
  });
  @override
  State<VerifyEmailPage> createState() =>
      _VerifyEmailPageState();
}
class _VerifyEmailPageState
    extends State<VerifyEmailPage> {
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
      setState(() {
        verifyError =
            "âš ï¸ La pergamena non risulta ancora firmata. Controlla la tua email.";
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
    setState(() {
      verifyError =
          "ðŸ“œ Nuova pergamena inviata. Controlla la tua casella email.";
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AtlasBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const AtlasHero(),
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
                        const Text(
                          "Verifica il tuo indirizzo email",
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Abbiamo inviato una email di verifica al tuo indirizzo.\n\nAprila e conferma il tuo account prima di entrare nella Taverna.",
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
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
                              style:
                                  const TextStyle(
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        AtlasPrimaryButton(
                          text:
                              "Ho verificato",
                          onPressed:
                              checkVerification,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed:
                              resendEmail,
                          child: const Text(
                            "Reinvia email",
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
