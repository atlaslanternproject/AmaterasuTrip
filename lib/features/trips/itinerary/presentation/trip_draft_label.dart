// Etichetta piccola e informativa della bozza di Itinerario e Mappa:
// "Bozza: dati di esempio, non si salva" (nessun banner decorativo).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripDraftLabel extends StatelessWidget {
  const TripDraftLabel({super.key});

  @override
  Widget build(BuildContext context) => Row(
    key: const Key('draft-label'),
    children: [
      const Icon(
        Icons.science_outlined,
        size: 14,
        color: AmaterasuColors.textMuted,
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          AppLocalizations.of(context)!.itineraryDraft,
          style: const TextStyle(
            color: AmaterasuColors.textMuted,
            fontSize: 12,
          ),
        ),
      ),
    ],
  );
}
