// Provider del modulo Luogo condiviso: ricerca dei luoghi Google (la stessa
// della bucket list e della creazione del viaggio) e dati extra del luogo
// (contatti e foto) con cache per tutta la sessione.

import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO(audit): il servizio di ricerca vive in create_trip (approvato); spostarlo in lib/core/places quando sarà consentito toccare quel modulo.
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';

import 'amaterasu_place_info.dart';
import 'amaterasu_place_info_cached.dart';

/// Google place search (autocomplete and details).
final amaterasuPlaceSearchProvider = Provider<DestinationPlacesService>(
  (ref) => const DestinationPlacesService(),
);

/// Contacts and photos of a Google place. Never disposed, so its cache
/// lasts for the whole session (one Google request per place).
final amaterasuPlaceInfoProvider = Provider<AmaterasuPlaceInfoService>(
  (ref) => CachedAmaterasuPlaceInfo(),
);
