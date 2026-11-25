// Intestazione comune delle pagine di "Altro": freccia indietro verso
// Altro, titolo grande con una riga piccola facoltativa sotto, e azioni a
// destra (il "+" delle sezioni; Aggiorna, Filtri e "+" in Itinerario).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

class TripSectionHeader extends StatelessWidget {
  const TripSectionHeader({
    super.key,
    required this.tripId,
    required this.title,
    this.action,
    this.actions = const [],
    this.subtitle,
    this.backRoute,
  });

  final String tripId;
  final String title;
  final Widget? action;

  /// More icons on the right (e.g. Aggiorna, Filtri, "+"), after [action].
  final List<Widget> actions;

  /// Small line under the title (e.g. the draft label), no extra row.
  final Widget? subtitle;

  /// Where the arrow goes; Altro when null (Itinerario: the trip home).
  final String? backRoute;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
    child: Row(
      children: [
        IconButton(
          onPressed: () => context.go(backRoute ?? '/trips/$tripId/more'),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AmaterasuColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AmaterasuColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ?subtitle,
            ],
          ),
        ),
        ?action,
        ...actions,
      ],
    ),
  );
}
