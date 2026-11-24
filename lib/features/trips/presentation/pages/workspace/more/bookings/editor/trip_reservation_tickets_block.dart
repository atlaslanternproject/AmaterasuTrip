// Blocco "Biglietti" dell'editor di una prenotazione: scadenza per
// prenotare (solo quando lo stato è "da prenotare"), intestatario, numero
// di biglietti e testo/codice del biglietto da mostrare come QR; campo di
// testo comune dell'editor.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_codec.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_pickers.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_reservation_draft.dart';

class TripReservationTicketsBlock extends StatelessWidget {
  const TripReservationTicketsBlock({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final TripReservationDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = draft;
    return TripSectionBlock(
      title: l10n.reservationBlockTickets,
      icon: Icons.qr_code_2_rounded,
      children: [
        if (d.status == TripBookingStatus.toBook)
          TripSectionDayButton(
            fieldKey: 'reservation-book-by',
            label: l10n.reservationBookBy,
            value: d.bookBy,
            onChanged: (v) {
              d.bookBy = v;
              onChanged();
            },
            onClear: () {
              d.bookBy = null;
              onChanged();
            },
          ),
        tripReservationText(
          'holder',
          d.holder,
          l10n.reservationHolder,
          TripSectionFields.shortMax,
        ),
        TextField(
          key: const Key('reservation-tickets'),
          controller: d.tickets,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 2,
          decoration: InputDecoration(labelText: l10n.reservationTickets),
        ),
        TextField(
          key: const Key('reservation-ticket-code'),
          controller: d.ticketCode,
          minLines: 1,
          maxLines: 4,
          maxLength: TripReservationCodec.ticketCodeMax,
          decoration: InputDecoration(
            labelText: l10n.reservationTicketCode,
            helperText: l10n.reservationTicketCodeHint,
            helperMaxLines: 3,
          ),
        ),
      ],
    );
  }
}

/// Text field of the reservation editor with key `reservation-KEY`.
Widget tripReservationText(
  String key,
  TextEditingController c,
  String label,
  int max, {
  int lines = 1,
}) => TextField(
  key: Key('reservation-$key'),
  controller: c,
  minLines: lines,
  maxLines: lines == 1 ? 1 : lines + 3,
  maxLength: max,
  decoration: InputDecoration(labelText: label),
);
