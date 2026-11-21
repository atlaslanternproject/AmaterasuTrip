// Pagina Hotel e alloggi del viaggio: elenco dei soggiorni ordinato per
// check-in, stato vuoto, avviso delle sovrapposizioni ed eliminazione
// (solo creatore o proprietario del viaggio).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'widgets/trip_stay_delete.dart';
import 'widgets/trip_stays_empty.dart';
import 'widgets/trip_stays_list.dart';

class TripHotelsPage extends ConsumerWidget {
  const TripHotelsPage({super.key, required this.tripId, this.launch});

  final String tripId;

  /// Replaces url_launcher in tests.
  final AmaterasuLaunch? launch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stays = ref.watch(tripStaysProvider(tripId));
    final repository = ref.watch(tripStaysRepositoryProvider);
    final ownerUid = ref.watch(tripStaysOwnerUidProvider(tripId));
    final names = ref.watch(tripStaysMemberNamesProvider(tripId));
    final uid = repository.currentUid;

    bool canDelete(TripStay stay) =>
        uid != null && (uid == stay.createdByUid || uid == ownerUid);

    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/trips/$tripId/more'),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AmaterasuColors.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      l10n.tripHotelsTitle,
                      style: const TextStyle(
                        color: AmaterasuColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: stays.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Text(
                    l10n.staysLoadError,
                    style: const TextStyle(color: AmaterasuColors.textSecondary),
                  ),
                ),
                data: (items) => items.isEmpty
                    ? const TripStaysEmpty()
                    : TripStaysList(
                        stays: items,
                        guestNameOf: (guestUid) =>
                            names[guestUid] ?? l10n.staysFormerGuest,
                        canDelete: canDelete,
                        onDelete: (stay) =>
                            confirmAndDeleteTripStay(context, repository, stay),
                        launch: launch,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
