// Sezione "Tipo di alloggio" dell'editor: hotel, B&B, appartamento,
// ostello, campeggio o altro, ognuno con la sua icona. È facoltativo:
// toccando di nuovo il tipo scelto lo si toglie.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_type.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../widgets/trip_stay_labels.dart';
import 'trip_stay_draft.dart';
import 'trip_stay_editor_section.dart';

class TripStayTypeSection extends StatelessWidget {
  const TripStayTypeSection({
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
      title: l10n.staysSectionType,
      icon: Icons.category_outlined,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final type in TripStayType.values)
              ChoiceChip(
                key: Key('stay-type-${type.code}'),
                avatar: Icon(TripStayLabels.typeIcon(type), size: 16,
                    color: AmaterasuColors.accentBudget),
                label: Text(TripStayLabels.type(type, l10n)),
                selected: draft.type == type,
                selectedColor:
                    AmaterasuColors.accentBudget.withValues(alpha: 0.25),
                onSelected: (selected) {
                  draft.type = selected ? type : null;
                  onChanged();
                },
              ),
          ],
        ),
      ],
    );
  }
}
