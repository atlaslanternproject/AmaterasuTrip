import 'package:amaterasutrip/features/auth/presentation/pages/auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:amaterasutrip/features/home/presentation/pages/home_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/verify_email_page.dart';
import '../features/auth/presentation/pages/create_username_page.dart';
import '../features/auth/presentation/pages/google_auth.dart';
import '../features/trips/presentation/pages/trips_page.dart';
import '../features/explore/presentation/pages/explore_page.dart';
import '../features/memories/presentation/pages/memories_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/settings/presentation/pages/profile/profile_page.dart';
import '../features/settings/presentation/pages/language/language_page.dart';
import '../features/settings/presentation/pages/notifications/notifications_page.dart';
import '../features/settings/presentation/pages/account/account_page.dart';
import '../features/settings/presentation/pages/privacy/privacy_page.dart';
import '../features/settings/presentation/pages/data/data_sync_page.dart';
import '../features/settings/presentation/pages/information/information_page.dart';
import '../features/settings/presentation/pages/notifications/notification_types_page.dart';
import '../features/settings/presentation/pages/notifications/notification_email_page.dart';

final amaterasuRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;

    final location = state.matchedLocation;

    if (user == null) {
      return null;
    }

    if (location == '/google-auth' || location == '/create-username') {
      return null;
    }

    if (location == '/') {
      return '/home';
    }

    return null;
  },
  routes: [
    // =========================
    // AUTENTICAZIONE
    // =========================
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
      path: '/google-auth',
      builder: (context, state) {
        return const GoogleAuth();
      },
    ),

    GoRoute(
      path: '/create-username',
      builder: (context, state) {
        return const CreateUsernamePage();
      },
    ),

    // =========================
    // APP PRINCIPALE
    // =========================
    GoRoute(
      path: '/home',
      builder: (context, state) {
        return const HomePage();
      },
    ),

    GoRoute(
      path: '/trips',
      builder: (context, state) {
        return const TripsPage();
      },
    ),

    GoRoute(
      path: '/explore',
      builder: (context, state) {
        return const ExplorePage();
      },
    ),

    GoRoute(
      path: '/memories',
      builder: (context, state) {
        return const MemoriesPage();
      },
    ),

    GoRoute(
      path: '/settings',
      builder: (context, state) {
        return const SettingsPage();
      },
    ),

    GoRoute(
      path: '/settings/profile',
      builder: (context, state) {
        return const ProfilePage();
      },
    ),

    GoRoute(
      path: '/settings/language',
      builder: (context, state) {
        return const LanguagePage();
      },
    ),

    GoRoute(
      path: '/settings/notifications',
      builder: (context, state) {
        return const NotificationsPage();
      },
    ),

    GoRoute(
      path: '/settings/notifications/types',
      builder: (context, state) {
        return const NotificationTypesPage();
      },
    ),

    GoRoute(
      path: '/settings/notifications/email',
      builder: (context, state) {
        return const NotificationEmailPage();
      },
    ),

    GoRoute(
      path: '/settings/account',
      builder: (context, state) {
        return const AccountPage();
      },
    ),

    GoRoute(
      path: '/settings/privacy',
      builder: (context, state) {
        return const PrivacyPage();
      },
    ),

    GoRoute(
      path: '/settings/data',
      builder: (context, state) {
        return const DataSyncPage();
      },
    ),

    GoRoute(
      path: '/settings/information',
      builder: (context, state) {
        return const InformationPage();
      },
    ),
  ],
);
