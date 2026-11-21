// Dati del viaggio che servono a Hotel/Alloggi: proprietario (per chi può
// eliminare) e nomi dei viaggiatori (per gli ospiti). Leggono i provider
// esistenti del viaggio e dei membri; nei test si sostituiscono facilmente.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/features/trips/providers/trip_member_provider.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';

/// Google place search, the same used by the Bucket List editor.
final tripStaysPlacesProvider = Provider<DestinationPlacesService>(
  (ref) => const DestinationPlacesService(),
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
