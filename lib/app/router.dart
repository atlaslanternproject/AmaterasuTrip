import 'package:amaterasutrip/features/auth/presentation/pages/auth_gate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:amaterasutrip/features/home/presentation/pages/home_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/verify_email_page.dart';
import '../features/auth/presentation/pages/create_username_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/presentation/pages/google_auth.dart';
final amaterasuRouter = GoRouter(
  initialLocation: '/',
  redirect:(context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final location = state.matchedLocation;
    if (user == null){
      return null;
    }
    final playerDoc = await FirebaseFirestore.instance
      .collection('/viaggiatori')
      .doc(user.uid)
      .get();
      if (!playerDoc.exists) {
        if (location == '/google-auth' ||
            location == '/create-username') {
          return null;
        }
        await FirebaseAuth.instance.signOut();
        return '/';
      }
    if (playerDoc.exists && location == '/'){
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const AuthGate();
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        return const RegisterPage();
      },
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) {
        return const VerifyEmailPage();
      },
    ),
    GoRoute(
      path:'/google-auth',
      builder: (context,state) {
        return const GoogleAuth();
      },
    ),
    GoRoute(
      path: '/create-username',
      builder: (context, state) {
        return const CreateUsernamePage();
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        return const HomePage();
      },
    ),
  ],
);


