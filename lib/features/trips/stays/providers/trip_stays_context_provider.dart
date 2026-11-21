// Dati del viaggio che servono a Hotel/Alloggi: proprietario (per chi può
// eliminare), nomi dei viaggiatori (per gli ospiti) e dati Google
// dell'alloggio (contatti e foto, con cache per la sessione). Leggono i provider
// esistenti del viaggio e dei membri; nei test si sostituiscono facilmente.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/features/trips/providers/trip_member_provider.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/features/trips/stays/places/trip_stay_place_info.dart';
import 'package:amaterasutrip/features/trips/stays/places/trip_stay_place_info_cached.dart';

/// Budget access used to create, link and show the expense of a stay.
final tripStaysBudgetApiProvider = Provider.family<BudgetApi, String>(
  (ref, tripId) => BudgetApi(tripId),
);

/// Google place search, the same used by the Bucket List editor.
final tripStaysPlacesProvider = Provider<DestinationPlacesService>(
  (ref) => const DestinationPlacesService(),
);

/// Contacts and photos of a Google place. Never disposed, so its cache
/// lasts for the whole session (one Google request per place).
final tripStayPlaceInfoProvider = Provider<TripStayPlaceInfoService>(
  (ref) => CachedTripStayPlaceInfo(),
);

final tripStaysOwnerUidProvider = Provider.autoDispose.family<String?, String>((
  ref,
  tripId,
) {
  return ref.watch(tripProvider(tripId)).asData?.value?.ownerUid;
});

/// Current travelers: uid -> name shown to the others.
final tripStaysMemberNamesProvider = Provider.autoDispose
    .family<Map<String, String>, String>((ref, tripId) {
      final members = ref.watch(tripMembersProvider(tripId)).asData?.value;
      if (members == null) return const {};
      return {
        for (final member in members)
          member.uid: member.displayName ?? member.uid,
      };
    });
