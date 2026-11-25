// Dettagli nella card di un soggiorno, sotto le date: "prenotato su" con
// il codice di conferma, costo previsto, servizi inclusi, come arrivare,
// arrivo tardivo, accesso, tassa di soggiorno e ospiti, come righe con
// icona.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/budget_money_formatter.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_extras_lines.dart';
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
    final bookedVia = TripStayLabels.bookedVia(stay, l10n);
    final code = stay.confirmationCode;
    final booking = [
      ?bookedVia,
      if (code != null) l10n.staysConfirmationCode(code),
    ].join(' · ');
    final cost = stay.estimatedCostMinorUnits;
    final currency = stay.estimatedCostCurrency;
    final amenities = stay.amenities
        .map((a) => TripStayLabels.amenity(a, l10n))
        .join(' · ');
    final directions = stay.directions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (booking.isNotEmpty)
          _line(Icons.confirmation_number_outlined, booking),
        if (cost != null && currency != null)
          _line(
            Icons.payments_outlined,
            l10n.staysCostEstimated(
              BudgetMoneyFormatter.format(cost, currency),
            ),
            key: const Key('stay-cost-line'),
          ),
        if (amenities.isNotEmpty)
          _line(
            Icons.room_service_outlined,
            l10n.staysAmenities(amenities),
            key: const Key('stay-amenities-line'),
          ),
        if (directions != null)
          _line(
            Icons.directions_outlined,
            '${l10n.staysDirections}: $directions',
            key: const Key('stay-directions-line'),
          ),
        for (final (icon, text, key) in tripStayExtrasLines(stay, l10n))
          _line(icon, text, key: key),
        if (guestNames.isNotEmpty)
          _line(Icons.people_outline, l10n.staysGuests(guestNames.join(', '))),
      ],
    );
  }

  Widget _line(IconData icon, String text, {Key? key}) => Padding(
    key: key,
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AmaterasuColors.textSecondary),
        const SizedBox(width: AmaterasuSpacing.sm),
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
