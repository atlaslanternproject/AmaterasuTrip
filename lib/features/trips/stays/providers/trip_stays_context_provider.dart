// Dati del viaggio che servono a Hotel/Alloggi: proprietario (per chi può
// eliminare) e nomi dei viaggiatori (per gli ospiti). Ricerca e dati
// Google del luogo sono in lib/core/places. Leggono i provider
// esistenti del viaggio e dei membri; nei test si sostituiscono facilmente.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import 'package:amaterasutrip/features/trips/providers/trip_member_provider.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';

/// Budget access used to create, link and show the expense of a stay.
final tripStaysBudgetApiProvider = Provider.family<BudgetApi, String>(
  (ref, tripId) => BudgetApi(tripId),
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
