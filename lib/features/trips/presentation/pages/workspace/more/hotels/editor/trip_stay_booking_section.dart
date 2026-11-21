// Sezione "Prenotazione" dell'editor: prenotato su (con "altro" a testo
// libero), link della prenotazione, link del sito dell'alloggio e codice.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_booking_platform.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_validator.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../widgets/trip_stay_labels.dart';
import 'trip_stay_draft.dart';
import 'trip_stay_editor_section.dart';

class TripStayBookingSection extends StatelessWidget {
  const TripStayBookingSection({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final TripStayDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String? linkError(TextEditingController controller) {
      final text = controller.text.trim();
      return text.isEmpty || AmaterasuWebLink.isValid(text)
          ? null
          : l10n.staysErrLink;
    }

    return TripStayEditorSection(
      title: l10n.staysSectionBooking,
      icon: Icons.confirmation_number_outlined,
      children: [
        DropdownButtonFormField<TripStayBookingPlatform?>(
          key: const Key('stay-booked-via'),
          initialValue: draft.bookedVia,
          decoration: InputDecoration(labelText: l10n.staysBookedViaLabel),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.staysBookedViaNone)),
            for (final platform in TripStayBookingPlatform.values)
              DropdownMenuItem(
                value: platform,
                child: Text(TripStayLabels.platform(platform, l10n)),
              ),
          ],
          onChanged: (value) {
            draft.bookedVia = value;
            onChanged();
          },
        ),
        if (draft.bookedVia == TripStayBookingPlatform.other)
          TextField(
            key: const Key('stay-booked-via-other'),
            controller: draft.bookedViaOther,
            maxLength: TripStayBookingPlatform.otherMaxLength,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(labelText: l10n.staysBookedViaOther),
          ),
        TextField(
          key: const Key('stay-booking-url'),
          controller: draft.bookingUrl,
          keyboardType: TextInputType.url,
          maxLength: AmaterasuWebLink.maxLength,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: l10n.staysBookingUrl,
            errorText: linkError(draft.bookingUrl),
            counterText: '',
          ),
        ),
        TextField(
          key: const Key('stay-property-url'),
          controller: draft.propertyUrl,
          keyboardType: TextInputType.url,
          maxLength: AmaterasuWebLink.maxLength,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: l10n.staysPropertyUrl,
            errorText: linkError(draft.propertyUrl),
            counterText: '',
          ),
        ),
        TextField(
          key: const Key('stay-code'),
          controller: draft.confirmationCode,
          maxLength: TripStayValidator.codeMax,
          decoration: InputDecoration(labelText: l10n.staysCode),
        ),
      ],
    );
  }
}
