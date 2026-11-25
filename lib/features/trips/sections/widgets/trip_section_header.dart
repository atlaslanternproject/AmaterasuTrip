// Intestazione comune delle pagine di "Altro": freccia indietro verso
// Altro, titolo grande e un'azione facoltativa a destra (il "+" delle
// sezioni). Estratta senza cambiamenti da TripSectionScaffold.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

class TripSectionHeader extends StatelessWidget {
  const TripSectionHeader({
    super.key,
    required this.tripId,
    required this.title,
    this.action,
  });

  final String tripId;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
    child: Row(
      children: [
        IconButton(
          onPressed: () => context.go('/trips/$tripId/more'),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AmaterasuColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AmaterasuColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ?action,
      ],
    ),
  );
}
