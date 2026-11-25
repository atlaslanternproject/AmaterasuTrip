// Sezioni in cui cerca "Cerca" (nuova tappa 2a) e lettura dei loro
// elementi con gli stessi store delle sezioni (note e checklist: solo
// condivise e proprie private). Letti alla prima ricerca e tenuti per la
// sessione; nessuna copia salvata altrove, nessuna API.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist_codec.dart';
import 'package:amaterasutrip/features/trips/checklists/providers/trip_checklists_provider.dart';
import 'package:amaterasutrip/features/trips/memories/models/trip_memory_codec.dart';
import 'package:amaterasutrip/features/trips/memories/providers/trip_memories_provider.dart';
import 'package:amaterasutrip/features/trips/notes/models/trip_note_codec.dart';
import 'package:amaterasutrip/features/trips/notes/providers/trip_notes_provider.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_codec.dart';
import 'package:amaterasutrip/features/trips/reservations/providers/trip_reservations_provider.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_codec.dart';
import 'package:amaterasutrip/features/trips/restaurants/providers/trip_restaurants_provider.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_codec.dart';
import 'package:amaterasutrip/features/trips/saved_places/providers/trip_saved_places_provider.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_section_store.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_shopping_codecs.dart';
import 'package:amaterasutrip/features/trips/shopping/providers/trip_shopping_provider.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_codec.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_provider.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_codec.dart';
import 'package:amaterasutrip/features/trips/transports/providers/trip_transports_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_search_text.dart';

enum TripSearchSection {
  stays('hotels', Icons.hotel_rounded),
  transports('transport', Icons.train_rounded),
  reservations('bookings', Icons.confirmation_number_rounded),
  restaurants('restaurants', Icons.restaurant_rounded),
  savedPlaces('saved-places', Icons.bookmark_rounded),
  notes('notes', Icons.notes_rounded),
  shopping('shopping', Icons.shopping_bag_rounded),
  checklists('checklists', Icons.checklist_rounded),
  memories('memories', Icons.photo_library_rounded);

  const TripSearchSection(this.page, this.icon);

  /// Page under /trips/{tripId}/more/.
  final String page;
  final IconData icon;

  /// Whether the section list highlights the tapped item.
  bool get highlights => this != stays && this != checklists;

  /// Where a tap on a result goes (a checklist opens its list).
  String route(String tripId, String id) => this == checklists
      ? '/trips/$tripId/more/checklists/$id'
      : '/trips/$tripId/more/$page';

  String label(AppLocalizations l10n) => switch (this) {
    stays => l10n.tripMoreHotels,
    transports => l10n.tripMoreTransport,
    reservations => l10n.tripMoreBookings,
    restaurants => l10n.tripMoreRestaurants,
    savedPlaces => l10n.tripMoreSavedPlaces,
    notes => l10n.tripMoreNotes,
    shopping => l10n.tripMoreShopping,
    checklists => l10n.tripMoreChecklists,
    memories => l10n.tripMoreMemories,
  };
}

/// One searchable element: its section, ID, name and texts.
class TripSearchDoc {
  const TripSearchDoc({
    required this.section,
    required this.id,
    required this.title,
    required this.texts,
  });

  final TripSearchSection section;
  final String id, title;
  final List<String> texts;
}

/// Reads all searchable elements of a trip, once, with the section stores.
typedef TripSearchLoader = Future<List<TripSearchDoc>> Function(String tripId);

final tripSearchLoaderProvider = Provider<TripSearchLoader>((ref) {
  Future<List<TripSearchDoc>> section<T extends TripSectionItem>(
    String tripId,
    TripSearchSection name,
    TripSectionStore<T> store,
    Map<String, dynamic> Function(T item) toMap,
  ) async {
    final items = await store.watch(tripId).first;
    return [
      for (final item in items)
        TripSearchDoc(
          section: name,
          id: item.id,
          title: item.displayName,
          texts: tripSearchTexts(toMap(item)),
        ),
    ];
  }

  return (tripId) async {
    final stays = ref.read(tripStaysRepositoryProvider).watch(tripId).first;
    final lists = await Future.wait([
      stays.then(
        (all) => [
          for (final s in all)
            TripSearchDoc(
              section: TripSearchSection.stays,
              id: s.id,
              title: s.name,
              texts: tripSearchTexts(TripStayCodec.toMap(s)),
            ),
        ],
      ),
      section(
        tripId,
        TripSearchSection.transports,
        ref.read(tripTransportsStoreProvider),
        const TripTransportCodec().toMap,
      ),
      section(
        tripId,
        TripSearchSection.reservations,
        ref.read(tripReservationsStoreProvider),
        const TripReservationCodec().toMap,
      ),
      section(
        tripId,
        TripSearchSection.restaurants,
        ref.read(tripRestaurantsStoreProvider),
        const TripRestaurantCodec().toMap,
      ),
      section(
        tripId,
        TripSearchSection.savedPlaces,
        ref.read(tripSavedPlacesStoreProvider),
        const TripSavedPlaceCodec().toMap,
      ),
      section(
        tripId,
        TripSearchSection.notes,
        ref.read(tripNotesStoreProvider),
        const TripNoteCodec().toMap,
      ),
      section(
        tripId,
        TripSearchSection.shopping,
        ref.read(tripShoppingStoreProvider),
        const TripShoppingItemCodec().toMap,
      ),
      section(
        tripId,
        TripSearchSection.checklists,
        ref.read(tripChecklistsStoreProvider),
        const TripChecklistCodec().toMap,
      ),
      section(
        tripId,
        TripSearchSection.memories,
        ref.read(tripMemoriesStoreProvider),
        const TripMemoryCodec().toMap,
      ),
    ]);
    return [for (final list in lists) ...list];
  };
});

/// Kept for the session; "Aggiorna" reads again.
final tripSearchDocsProvider =
    FutureProvider.family<List<TripSearchDoc>, String>(
      (ref, tripId) => ref.watch(tripSearchLoaderProvider)(tripId),
    );
