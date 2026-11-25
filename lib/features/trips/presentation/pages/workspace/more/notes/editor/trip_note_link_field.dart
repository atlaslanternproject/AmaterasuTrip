// Campo "Collega a un elemento" dell'editor di una nota: mostra il
// collegamento scelto (con l'icona della sezione) e apre un pannello con
// gli elementi del viaggio letti su richiesta. Si può anche togliere.

import 'package:amaterasutrip/core/widgets/common/amaterasu_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_sheet.dart';
import 'package:amaterasutrip/features/trips/notes/models/trip_note.dart';
import 'package:amaterasutrip/features/trips/notes/providers/trip_note_link_targets.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../widgets/trip_note_entry.dart';

class TripNoteLinkField extends StatelessWidget {
  const TripNoteLinkField({
    super.key,
    required this.tripId,
    required this.link,
    required this.onChanged,
  });

  final String tripId;
  final TripNoteLink? link;
  final ValueChanged<TripNoteLink?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showAmaterasuSheet<TripNoteLink>(
      context,
      builder: (_) => _TargetsSheet(tripId: tripId),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = link;
    return Row(
      children: [
        Expanded(
          child: current == null
              ? Text(
                  l10n.noteLinkNone,
                  style: const TextStyle(color: AmaterasuColors.textMuted),
                )
              : Row(
                  children: [
                    Icon(
                      TripNoteLabels.sectionIcon(current.section),
                      size: 18,
                      color: AmaterasuColors.accentGold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(current.name)),
                  ],
                ),
        ),
        if (current != null)
          IconButton(
            key: const Key('note-link-clear'),
            tooltip: l10n.noteLinkRemove,
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.link_off_rounded),
          ),
        AmaterasuButton.secondary(
          key: const Key('note-link-pick'),
          icon: Icons.link_rounded,
          label: l10n.noteLinkPick,
          onPressed: () => _pick(context),
        ),
      ],
    );
  }
}

class _TargetsSheet extends ConsumerWidget {
  const _TargetsSheet({required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final targets = ref.watch(tripNoteLinkTargetsProvider(tripId));
    return SizedBox(
      height: 420,
      child: targets.when(
        loading: () => const Center(child: AmaterasuLoader()),
        error: (_, _) => Center(child: Text(l10n.sectionsLoadError)),
        data: (list) => list.isEmpty
            ? Center(child: Text(l10n.noteLinkEmpty))
            : Material(
                type: MaterialType.transparency,
                child: ListView(
                  children: [
                    for (final target in list)
                      ListTile(
                        key: Key('note-link-${target.section}-${target.id}'),
                        leading: Icon(
                          TripNoteLabels.sectionIcon(target.section),
                          color: AmaterasuColors.accentGold,
                        ),
                        title: Text(target.name),
                        subtitle: Text(
                          TripNoteLabels.section(target.section, l10n),
                        ),
                        onTap: () => Navigator.pop(context, target),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
