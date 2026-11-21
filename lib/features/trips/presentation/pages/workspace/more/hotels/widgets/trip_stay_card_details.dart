// Dettagli nella card di un soggiorno: check-in e check-out con orari,
// numero di notti, città, "prenotato su", codice e ospiti.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_labels.dart';

class TripStayCardDetails extends StatelessWidget {
  const TripStayCardDetails({
    super.key,
    required this.stay,
    required this.guestNames,
  });

  final TripStay stay;
  final List<String> guestNames;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final place = [stay.city, stay.country]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(', ');
    final bookedVia = TripStayLabels.bookedVia(stay, l10n);
    final code = stay.confirmationCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AmaterasuSpacing.lg,
          runSpacing: AmaterasuSpacing.sm,
          children: [
            _Day(
              label: l10n.staysCheckIn,
              value: TripStayLabels.day(
                context, stay.checkInDate, stay.checkInTime),
            ),
            _Day(
              label: l10n.staysCheckOut,
              value: TripStayLabels.day(
                context, stay.checkOutDate, stay.checkOutTime),
            ),
            _Day(label: '', value: l10n.staysNights(stay.nights)),
          ],
        ),
        if (place.isNotEmpty) _line(Icons.place_outlined, place),
        if (bookedVia != null) _line(Icons.confirmation_number_outlined,
            code == null ? bookedVia : '$bookedVia · ${l10n.staysConfirmationCode(code)}'),
        if (bookedVia == null && code != null)
          _line(Icons.confirmation_number_outlined,
              l10n.staysConfirmationCode(code)),
        if (guestNames.isNotEmpty)
          _line(Icons.people_outline, l10n.staysGuests(guestNames.join(', '))),
      ],
    );
  }

  Widget _line(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: AmaterasuSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AmaterasuColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AmaterasuColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Day extends StatelessWidget {
  const _Day({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AmaterasuColors.textMuted, fontSize: 12),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          color: AmaterasuColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
