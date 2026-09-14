import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:amaterasutrip/features/auth/providers/auth_controller.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class GoogleAuth extends ConsumerStatefulWidget {
  const GoogleAuth({super.key});
  @override
  ConsumerState<GoogleAuth> createState() => _GoogleAuthState();
}

class _GoogleAuthState extends ConsumerState<GoogleAuth> {
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _login();
    });
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final credential = await ref
          .read(authControllerProvider)
          .loginWithGoogle();
      if (!mounted) return;
      if (credential == null) {
        context.go('/');
        return;
      }
      final user = credential.user;
      if (user == null) {
        context.go('/');
        return;
      }
      debugPrint("GOOGLE LOGIN OK");
      debugPrint("UID: ${user.uid}");
      debugPrint("EMAIL: ${user.email}");
      final playerDoc = await FirebaseFirestore.instance
          .collection('viaggiatori')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      if (playerDoc.exists) {
        debugPrint("PLAYER ESISTE -> HOME");
        context.go('/home');
      } else {
        debugPrint("PLAYER NON ESISTE -> CREATE USERNAME");
        context.go('/create-username');
      }
    } catch (e) {
      debugPrint("GOOGLE AUTH ERROR");
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() {
        error = l10n.authGoogleSignInError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: error == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    l10n.authGoogleSigningIn,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(error!),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: null, child: Text(l10n.authRetry)),
                ],
              ),
      ),
    );
  }
}
