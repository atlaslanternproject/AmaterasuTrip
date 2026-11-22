// Sezione "Stato" dell'editor: prenotato, da confermare o annullato, con
// gli stessi colori della card.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../widgets/trip_stay_labels.dart';
import 'trip_stay_draft.dart';
import 'trip_stay_editor_section.dart';

class TripStayStatusSection extends StatelessWidget {
  const TripStayStatusSection({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final TripStayDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TripStayEditorSection(
      title: l10n.staysSectionStatus,
      icon: Icons.flag_outlined,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final status in TripStayStatus.values)
              ChoiceChip(
                key: Key('stay-status-${status.code}'),
                label: Text(TripStayLabels.status(status, l10n)),
                selected: draft.status == status,
                selectedColor: TripStayLabels.statusColor(
                  status,
                ).withValues(alpha: 0.25),
                onSelected: (_) {
                  draft.status = status;
                  onChanged();
                },
              ),
          ],
        ),
      ],
    );
  }
}
