// Calcoli delle Statistiche (tappa 3b), senza spese (quelle arrivano già
// sommate dal modulo del budget): notti negli alloggi, città e paesi degli
// alloggi, trasporti per tipo, ristoranti provati con voto medio, luoghi
// visitati. Gli elementi annullati non contano.

import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_status.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_type.dart';
import 'trip_stats_data.dart';

class TripStats {
  const TripStats({
    required this.nights,
    required this.cities,
    required this.countries,
    required this.transportsByType,
    required this.restaurants,
    required this.tried,
    required this.averageRating,
    required this.places,
    required this.visited,
  });

  factory TripStats.from(TripStatsData data) {
    final stays = data.stays.where((s) => s.status != TripStayStatus.cancelled);
    final byType = <TripTransportType, int>{};
    for (final t in data.transports) {
      if (t.status == TripBookingStatus.cancelled) continue;
      byType[t.type] = (byType[t.type] ?? 0) + 1;
    }
    final tried = data.restaurants
        .where((r) => r.status == TripRestaurantStatus.tried)
        .toList();
    final ratings = [for (final r in tried) ?r.triedRating];
    String key(String text) => text.trim().toLowerCase();
    Set<String> distinct(Iterable<String?> values) {
      final seen = <String, String>{};
      for (final v in values) {
        if (v != null && v.trim().isNotEmpty) seen.putIfAbsent(key(v), v.trim);
      }
      return seen.values.toSet();
    }

    return TripStats(
      nights: stays.fold(0, (sum, s) => sum + s.nights),
      cities: distinct(stays.map((s) => s.city)),
      countries: distinct(stays.map((s) => s.country)),
      transportsByType: byType,
      restaurants: data.restaurants.length,
      tried: tried.length,
      averageRating: ratings.isEmpty
          ? null
          : ratings.reduce((a, b) => a + b) / ratings.length,
      places: data.places.length,
      visited: data.places.where((p) => p.visited).length,
    );
  }

  final int nights;
  final Set<String> cities, countries;
  final Map<TripTransportType, int> transportsByType;
  final int restaurants, tried, places, visited;
  final double? averageRating;
}
