// Dati delle Statistiche (tappa 3b), letti una volta all'apertura della
// pagina con le letture esistenti: alloggi, trasporti, ristoranti, luoghi
// e spese condivise in cui partecipo, con i totali del modulo condiviso
// del budget (stessi tassi, stessi filtri predefiniti del cruscotto).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/budget/data/budget_fx_service.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_category_totals.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_filters.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/providers/trip_restaurants_provider.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place.dart';
import 'package:amaterasutrip/features/trips/saved_places/providers/trip_saved_places_provider.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_provider.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/providers/trip_transports_provider.dart';

/// Shared expenses of the budget, already converted to [currency].
class TripStatsExpenses {
  const TripStatsExpenses({
    required this.currency,
    required this.totals,
    required this.customCategories,
    required this.names,
  });

  final String currency;
  final BudgetCategoryTotals totals;
  final Map<String, String> customCategories;

  /// Username of each traveler (the budget's shared name list).
  final Map<String, String> names;
}

class TripStatsData {
  const TripStatsData({
    this.stays = const [],
    this.transports = const [],
    this.restaurants = const [],
    this.places = const [],
    this.expenses,
  });

  final List<TripStay> stays;
  final List<TripTransport> transports;
  final List<TripRestaurant> restaurants;
  final List<TripSavedPlace> places;

  /// Null when the budget cannot be read now (the rest still shows).
  final TripStatsExpenses? expenses;
}

typedef TripStatsLoader = Future<TripStatsData> Function(String tripId);

final tripStatsLoaderProvider = Provider<TripStatsLoader>(
  (ref) => (tripId) async {
    final stays = ref.read(tripStaysRepositoryProvider).watch(tripId).first;
    final transports = ref
        .read(tripTransportsStoreProvider)
        .watch(tripId)
        .first;
    final restaurants = ref
        .read(tripRestaurantsStoreProvider)
        .watch(tripId)
        .first;
    final places = ref.read(tripSavedPlacesStoreProvider).watch(tripId).first;
    TripStatsExpenses? expenses;
    try {
      final api = ref.read(tripStaysBudgetApiProvider(tripId));
      final currency = await api.tripCurrency();
      final now = DateTime.now();
      const filters = BudgetExpenseFilters();
      final docs = (await api.sharedExpenses().first).docs
          .where((doc) => filters.matches(doc.data(), now))
          .toList();
      final quotes = await budgetCategoryQuotes(
        docs,
        currency,
        BudgetFxService(),
      );
      expenses = TripStatsExpenses(
        currency: currency,
        totals: BudgetCategoryTotals.compute(
          docs,
          currency,
          quotes,
          api.currentUid,
        ),
        customCategories: await api.budgetCategories().first,
        names: await api.travelerNameMap,
      );
    } catch (_) {
      expenses = null;
    }
    return TripStatsData(
      stays: await stays,
      transports: await transports,
      restaurants: await restaurants,
      places: await places,
      expenses: expenses,
    );
  },
);

/// Read once when the page opens; kept while it is open.
final tripStatsProvider = FutureProvider.autoDispose
    .family<TripStatsData, String>(
      (ref, tripId) => ref.watch(tripStatsLoaderProvider)(tripId),
    );
