// Import della vecchia lista valigia di Shopping nella nuova sezione
// Checklist: compare solo se ci sono ancora voci; crea una checklist
// condivisa "Valigia" con quantità, persona e spunte, poi toglie le vecchie
// voci (quelle che l'utente può eliminare).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist.dart';
import 'package:amaterasutrip/features/trips/checklists/providers/trip_checklists_provider.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_notice.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_packing_item.dart';
import 'package:amaterasutrip/features/trips/shopping/providers/trip_shopping_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

/// The imported list, one category for everyone and one per person.
TripChecklist tripChecklistFromPacking({
  required List<TripPackingItem> items,
  required String tripId,
  required String authorUid,
  required String title,
  required String everyone,
}) {
  final entries = <String, TripChecklistEntry>{};
  for (final item in items) {
    final id = 'p${entries.length + 1}';
    entries[id] = TripChecklistEntry(
      id: id,
      text: item.name,
      category: everyone,
      quantity: item.quantity,
      assigneeUid: item.personUid,
      done: item.packed,
      order: entries.length,
    );
  }
  return TripChecklist(
    tripId: tripId,
    createdByUid: authorUid,
    title: title,
    template: 'packing',
    categories: [everyone],
    entries: entries,
  );
}

class TripChecklistImport extends ConsumerWidget {
  const TripChecklistImport({super.key, required this.tripId});

  final String tripId;

  Future<void> _import(
    BuildContext context,
    WidgetRef ref,
    List<TripPackingItem> items,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final store = ref.read(tripChecklistsStoreProvider);
    final uid = store.currentUid;
    if (uid == null) return;
    try {
      await store.create(
        tripChecklistFromPacking(
          items: items,
          tripId: tripId,
          authorUid: uid,
          title: l10n.checklistTplPacking,
          everyone: l10n.packingForEveryone,
        ),
      );
      final packing = ref.read(tripPackingStoreProvider);
      for (final item in items) {
        try {
          await packing.delete(item);
        } catch (_) {
          // Only the author or the owner may delete: the rest stays.
        }
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.checklistImported)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.sectionsSaveError)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(tripPackingProvider(tripId)).asData?.value;
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TripSectionNotice(
              icon: Icons.luggage_outlined,
              lines: [l10n.checklistImportText(items.length)],
            ),
            AmaterasuButton.secondary(
              key: const Key('checklist-import'),
              label: l10n.checklistImport,
              onPressed: () => _import(context, ref, items),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
