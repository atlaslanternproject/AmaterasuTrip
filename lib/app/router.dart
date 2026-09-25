import 'package:amaterasutrip/features/auth/presentation/pages/auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:amaterasutrip/features/home/presentation/pages/home_page.dart';

import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/verify_email_page.dart';
import '../features/auth/presentation/pages/create_username_page.dart';
import '../features/auth/presentation/pages/google_auth.dart';

import '../features/trips/presentation/pages/trips_page.dart';
import '../features/trips/presentation/pages/create_trip/create_trip_page.dart';

import '../features/trips/presentation/pages/workspace/overview/trip_overview_page.dart';
import '../features/trips/presentation/pages/workspace/itinerary/trip_itinerary_page.dart';
import '../features/trips/presentation/pages/workspace/bucket_list/trip_bucket_list_page.dart';
import '../features/trips/presentation/pages/workspace/more/trip_more_page.dart';

import '../features/trips/presentation/pages/workspace/map/trip_map_page.dart';
import '../features/trips/presentation/pages/workspace/expenses/trip_expenses_page.dart';
import '../features/trips/presentation/pages/workspace/travellers/trip_travellers_page.dart';

import '../features/trips/presentation/pages/workspace/more/restaurants/trip_restaurants_page.dart';
import '../features/trips/presentation/pages/workspace/more/hotels/trip_hotels_page.dart';
import '../features/trips/presentation/pages/workspace/more/shopping/trip_shopping_page.dart';
import '../features/trips/presentation/pages/workspace/more/transport/trip_transport_page.dart';
import '../features/trips/presentation/pages/workspace/more/bookings/trip_bookings_page.dart';
import '../features/trips/presentation/pages/workspace/more/saved_places/trip_saved_places_page.dart';
import '../features/trips/presentation/pages/workspace/more/memories/trip_memories_page.dart';
import '../features/trips/presentation/pages/workspace/more/notes/trip_notes_page.dart';

import '../features/trips/presentation/pages/workspace/settings/trip_settings_page.dart';
import '../features/trips/presentation/pages/workspace/settings/information/trip_information_settings_page.dart';
import '../features/trips/presentation/pages/workspace/settings/travellers/trip_travellers_settings_page.dart';
import '../features/trips/presentation/pages/workspace/settings/notifications/trip_notifications_settings_page.dart';
import '../features/trips/presentation/pages/workspace/settings/privacy/trip_privacy_settings_page.dart';
import '../features/trips/presentation/pages/workspace/settings/management/trip_management_settings_page.dart';

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
        final initialIndex = state.extra is int
            ? state.extra as int
            : 0;

        return HomePage(
          initialIndex: initialIndex,
        );
      },
    ),

    // =========================
    // VIAGGI
    // =========================
    GoRoute(
      path: '/trips',
      builder: (context, state) {
        return const TripsPage();
      },
    ),

    GoRoute(
      path: '/trips/create',
      builder: (context, state) {
        return const CreateTripPage();
      },
    ),

    // =========================
    // WORKSPACE VIAGGIO
    // =========================

    // Panoramica
    GoRoute(
      path: '/trips/:tripId',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripOverviewPage(tripId: tripId);
      },
    ),

    // Itinerario
    GoRoute(
      path: '/trips/:tripId/itinerary',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripItineraryPage(tripId: tripId);
      },
    ),

    // Bucket List
    GoRoute(
      path: '/trips/:tripId/bucket-list',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripBucketListPage(tripId: tripId);
      },
    ),

    // =========================
    // ALTRO
    // =========================
    GoRoute(
      path: '/trips/:tripId/more',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripMorePage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/more/map',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripMapPage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/more/expenses',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripExpensesPage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/more/travellers',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripTravellersPage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/more/restaurants',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripRestaurantsPage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/more/hotels',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripHotelsPage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/more/shopping',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripShoppingPage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/more/transport',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripTransportPage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/more/bookings',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripBookingsPage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/more/saved-places',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripSavedPlacesPage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/more/memories',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripMemoriesPage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/more/notes',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripNotesPage(tripId: tripId);
      },
    ),

    // =========================
    // IMPOSTAZIONI VIAGGIO
    // =========================
    GoRoute(
      path: '/trips/:tripId/settings',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripSettingsPage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/settings/information',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripInformationSettingsPage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/settings/travellers',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripTravellersSettingsPage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/settings/notifications',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripNotificationsSettingsPage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/settings/privacy',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripPrivacySettingsPage(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/trips/:tripId/settings/management',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;

        return TripManagementSettingsPage(tripId: tripId);
      },
    ),

    // =========================
    // IMPOSTAZIONI APP
    // =========================
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