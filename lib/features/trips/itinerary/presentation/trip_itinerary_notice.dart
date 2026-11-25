// Avviso solo informativo dell'Itinerario (es. due voci a meno di un'ora
// di distanza): icona e testo nel colore oro, nessun blocco.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

class TripItineraryNotice extends StatelessWidget {
  const TripItineraryNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          size: 18,
          color: AmaterasuColors.accentGold,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AmaterasuColors.accentGold),
          ),
        ),
      ],
    ),
  );
}
