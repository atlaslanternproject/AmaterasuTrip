// Dati veri della Mappa (solo lettura, una volta per apertura): tutti gli
// elementi con posizione di alloggi, trasporti (partenza e arrivo),
// prenotazioni, ristoranti, luoghi salvati e bucket list, con gli store e
// le letture che le sezioni già hanno. Annullati esclusi; quelli senza
// posizione non compaiono ma si contano. Anche il catalogo degli elementi
// (con e senza posizione) per l'Itinerario.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/reservations/providers/trip_reservations_provider.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_status.dart';
import 'package:amaterasutrip/features/trips/restaurants/providers/trip_restaurants_provider.dart';
import 'package:amaterasutrip/features/trips/saved_places/providers/trip_saved_places_provider.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_bucket_reader.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_provider.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';
import 'package:amaterasutrip/features/trips/transports/providers/trip_transports_provider.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_ref.dart';
import 'trip_map_builders.dart';
import 'trip_map_point.dart';

typedef TripMapData = ({
  List<TripMapPoint> points,
  int withoutPosition,
  List<TripItineraryRef> catalog,
});

typedef TripMapLoader = Future<TripMapData> Function(String tripId);

final tripMapLoaderProvider = Provider<TripMapLoader>(
  (ref) => (tripId) async {
    final stays = ref.read(tripStaysRepositoryProvider).watch(tripId).first;
    final transports = ref
        .read(tripTransportsStoreProvider)
        .watch(tripId)
        .first;
    final reservations = ref
        .read(tripReservationsStoreProvider)
        .watch(tripId)
        .first;
    final restaurants = ref
        .read(tripRestaurantsStoreProvider)
        .watch(tripId)
        .first;
    final places = ref.read(tripSavedPlacesStoreProvider).watch(tripId).first;
    final bucket = ref.read(tripBucketReaderProvider)(tripId);
    final out = TripMapPoints();
    for (final x in await stays) {
      if (x.status == TripStayStatus.cancelled) continue;
      out.add(
        [
          tripMapPointAt(
            'stay-${x.id}',
            TripSearchSection.stays,
            x.id,
            x.name,
            x.latitude,
            x.longitude,
            zone: x.city,
            day: x.checkInDate,
            time: x.checkInTime,
            status: x.status == TripStayStatus.booked
                ? TripBookingStatus.booked
                : TripBookingStatus.toBook,
            person: x.createdByUid,
          ),
        ],
        TripItineraryRef(
          section: TripSearchSection.stays,
          refId: x.id,
          title: x.name,
          zone: x.city,
          status: x.status == TripStayStatus.booked
              ? TripBookingStatus.booked
              : TripBookingStatus.toBook,
        ),
      );
    }
    for (final t in await transports) {
      if (t.status == TripBookingStatus.cancelled) continue;
      final title = t.route.isEmpty ? (t.carrier ?? '') : t.route;
      out.add(
        [
          tripMapPointOf(
            'transport-${t.id}-from',
            TripSearchSection.transports,
            t.id,
            title,
            t.from,
            zone: t.extras.departureCity,
            day: t.departureDate,
            time: t.departureTime,
            status: t.status,
            person: t.createdByUid,
          ),
          tripMapPointOf(
            'transport-${t.id}-to',
            TripSearchSection.transports,
            t.id,
            title,
            t.to,
            zone: t.extras.arrivalCity,
            day: t.arrivalDate ?? t.departureDate,
            time: t.arrivalTime,
            status: t.status,
            person: t.createdByUid,
          ),
        ],
        TripItineraryRef(
          section: TripSearchSection.transports,
          refId: t.id,
          title: title,
          zone: t.extras.departureCity,
          status: t.status,
        ),
      );
    }
    for (final r in await reservations) {
      if (r.status == TripBookingStatus.cancelled) continue;
      out.add(
        [
          tripMapPointOf(
            'reservation-${r.id}',
            TripSearchSection.reservations,
            r.id,
            r.name,
            r.place,
            zone: r.zoneCity,
            day: r.date,
            time: r.time,
            status: r.status,
            person: r.createdByUid,
          ),
        ],
        TripItineraryRef(
          section: TripSearchSection.reservations,
          refId: r.id,
          title: r.name,
          zone: r.zoneCity,
          status: r.status,
        ),
      );
    }
    for (final r in await restaurants) {
      out.add(
        [
          tripMapPointOf(
            'restaurant-${r.id}',
            TripSearchSection.restaurants,
            r.id,
            r.name,
            r.place,
            zone: r.zoneCity,
            day: r.reservationDate,
            time: r.reservationTime,
            status: r.status == TripRestaurantStatus.booked
                ? TripBookingStatus.booked
                : null,
            person: r.createdByUid,
          ),
        ],
        TripItineraryRef(
          section: TripSearchSection.restaurants,
          refId: r.id,
          title: r.name,
          zone: r.zoneCity,
          status: r.status == TripRestaurantStatus.booked
              ? TripBookingStatus.booked
              : null,
        ),
      );
    }
    for (final p in await places) {
      out.add(
        [
          tripMapPointOf(
            'place-${p.id}',
            TripSearchSection.savedPlaces,
            p.id,
            p.name,
            p.place,
            zone: p.area,
            day: p.plannedDay,
            person: p.createdByUid,
          ),
        ],
        TripItineraryRef(
          section: TripSearchSection.savedPlaces,
          refId: p.id,
          title: p.name,
          zone: p.area,
        ),
      );
    }
    for (final b in await bucket) {
      out.add(
        [
          tripMapPointAt(
            'bucket-${b.id}',
            TripSearchSection.bucketList,
            b.id,
            b.name,
            b.latitude,
            b.longitude,
            zone: b.city,
            person: b.createdByUid,
          ),
        ],
        TripItineraryRef(
          section: TripSearchSection.bucketList,
          refId: b.id,
          title: b.name,
          zone: b.city,
        ),
      );
    }
    return (
      points: out.points,
      withoutPosition: out.missing,
      catalog: out.catalog,
    );
  },
);

/// Read once per opening of the page; "Aggiorna" reads again.
final tripMapDataProvider = FutureProvider.autoDispose
    .family<TripMapData, String>(
      (ref, tripId) => ref.watch(tripMapLoaderProvider)(tripId),
    );
