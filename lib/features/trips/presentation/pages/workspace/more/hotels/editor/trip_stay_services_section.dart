// Sezione "Servizi e come arrivare" dell'editor: servizi inclusi
// (colazione, parcheggio, Wi-Fi, cucina), ognuno con la sua icona e
// spuntabile, e un testo libero su come raggiungere l'alloggio.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_amenity.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_validator.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../widgets/trip_stay_labels.dart';
import 'trip_stay_draft.dart';
import 'trip_stay_editor_section.dart';

class TripStayServicesSection extends StatelessWidget {
  const TripStayServicesSection({
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
      title: l10n.staysSectionServices,
      icon: Icons.room_service_outlined,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final amenity in TripStayAmenity.values)
              FilterChip(
                key: Key('stay-amenity-${amenity.code}'),
                avatar: Icon(
                  TripStayLabels.amenityIcon(amenity),
                  size: 16,
                  color: AmaterasuColors.accentBudget,
                ),
                showCheckmark: false,
                label: Text(TripStayLabels.amenity(amenity, l10n)),
                selected: draft.amenities.contains(amenity),
                selectedColor: AmaterasuColors.accentBudget.withValues(
                  alpha: 0.25,
                ),
                onSelected: (selected) {
                  selected
                      ? draft.amenities.add(amenity)
                      : draft.amenities.remove(amenity);
                  onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('stay-directions'),
          controller: draft.directions,
          minLines: 2,
          maxLines: 5,
          maxLength: TripStayValidator.directionsMax,
          decoration: InputDecoration(labelText: l10n.staysDirections),
        ),
      ],
    );
  }
}
