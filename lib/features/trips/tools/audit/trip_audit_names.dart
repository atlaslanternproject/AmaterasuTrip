// Nomi nel registro (Audit Trail): lo username con la funzione condivisa
// (regola 2); un membro senza profilo è un account cancellato ("Utente
// eliminato"); chi non è più tra i membri è un "Ex viaggiatore". Il
// registro salva solo l'identificativo, mai nomi o email.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/models/trip_member_name.dart';
import 'package:amaterasutrip/features/trips/providers/trip_member_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

/// Current members: uid -> username, or null when the account is deleted.
final tripAuditMembersProvider = Provider.autoDispose
    .family<Map<String, String?>, String>((ref, tripId) {
      final members = ref.watch(tripMembersProvider(tripId)).asData?.value;
      if (members == null) return const {};
      return {
        for (final m in members)
          m.uid: switch (tripMemberShownName(m)?.trim()) {
            final name? when name.isNotEmpty => name,
            _ => null,
          },
      };
    });

String tripAuditName(
  AppLocalizations l10n,
  Map<String, String?> members,
  String? uid,
) {
  if (uid == null) return l10n.auditUnknownPerson;
  if (!members.containsKey(uid)) return l10n.auditFormerTraveler;
  return members[uid] ?? l10n.auditDeletedUser;
}
