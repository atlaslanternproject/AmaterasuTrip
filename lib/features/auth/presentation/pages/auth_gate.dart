import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import 'auth_page.dart';
import 'package:amaterasutrip/features/profile/providers/user_provider.dart';
import 'package:amaterasutrip/features/home/presentation/pages/home_page.dart';
import 'package:amaterasutrip/core/notifications/firebase_messaging_service.dart';
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});
  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      loading: () {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (error, stack) {
        return Scaffold(body: Center(child: Text(error.toString())));
      },
      data: (user) {
        debugPrint("USER FIREBASE: ${user?.email}");
        if (user != null && user.email != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await ref
                  .read(userRepositoryProvider)
                  .updateEmail(email: user.email!);
              debugPrint("FIRESTORE EMAIL SYNC: ${user.email}");
            } catch (error) {
              debugPrint("FIRESTORE EMAIL SYNC ERROR: $error");
            }
            await FirebaseMessagingService.instance.syncCurrentUserToken();
          });
        }
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final prefs = snapshot.data!;
            final rememberMe = prefs.getBool('remember_me') ?? false;
            debugPrint("REMEMBER LETTO: $rememberMe");
            /*
              Nessun utente Firebase
              -> login
            */
            if (user == null) {
              return const AuthPage();
            }
            /*
              Utente loggato:
              resta dentro.
              Remember me serve solo
              per il prossimo avvio.
            */
            if (!rememberMe) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await ref.read(authRepositoryProvider).signOut();
              });
              return const AuthPage();
            }
            return const HomePage();
          },
        );
      },
    );
  }
}
