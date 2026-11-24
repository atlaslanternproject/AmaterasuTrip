// Biglietto di una prenotazione a schermo intero: il codice scritto
// nell'editor diventa un codice QR (generato nel telefono, nessun file
// caricato), con nome, data e codice in chiaro sotto.

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

Future<void> showTripReservationTicket(
  BuildContext context,
  TripReservation item,
  String when,
) => showDialog<void>(
  context: context,
  barrierColor: Colors.black,
  builder: (dialogContext) {
    final l10n = AppLocalizations.of(dialogContext)!;
    final code = item.ticketCode ?? '';
    return Dialog.fullscreen(
      backgroundColor: AmaterasuColors.surfaceDeep,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              key: Key('reservation-ticket-view-${item.id}'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AmaterasuColors.textCream,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (when.isNotEmpty)
                  Text(
                    when,
                    style: const TextStyle(color: AmaterasuColors.accentGold),
                  ),
                const SizedBox(height: 20),
                // White background so that any scanner reads the code.
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: QrImageView(data: code, size: 260),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AmaterasuColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                AmaterasuButton.secondary(
                  key: const Key('reservation-ticket-close'),
                  label: l10n.placesContactClose,
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
);
