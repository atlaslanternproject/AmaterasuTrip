// Card di un soggiorno: nome, stato, tipo di alloggio, date e orari, notti, luogo,
// prenotazione, link, mappa, ospiti, spesa collegata (se data) e menu con
// modifica ed eliminazione (solo creatore o proprietario del viaggio).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_card_details.dart';
import 'trip_stay_card_links.dart';
import 'trip_stay_labels.dart';
import 'trip_stay_status_chip.dart';
import 'trip_stay_type_chip.dart';

enum _StayAction { edit, delete }

class TripStayCard extends StatelessWidget {
  const TripStayCard({
    super.key,
    required this.stay,
    required this.guestNames,
    required this.canDelete,
    this.onEdit,
    this.onDelete,
    this.footer,
    this.launch,
  });

  final TripStay stay;
  final List<String> guestNames;
  final bool canDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Extra content at the bottom (linked expense).
  final Widget? footer;
  final AmaterasuLaunch? launch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cancelled = !stay.isActive;
    final actions = [
      if (onEdit != null) _StayAction.edit,
      if (canDelete && onDelete != null) _StayAction.delete,
    ];

    return Container(
      key: Key('stay-card-${stay.id}'),
      padding: const EdgeInsets.all(AmaterasuSpacing.md),
      decoration: BoxDecoration(
        color: AmaterasuColors.surfaceWarm,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AmaterasuColors.borderAccent.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(TripStayLabels.typeIcon(stay.type),
                    color: AmaterasuColors.accentBudget, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: AmaterasuSpacing.sm,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      stay.name,
                      style: TextStyle(
                        color: cancelled
                            ? AmaterasuColors.textMuted
                            : AmaterasuColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        decoration:
                            cancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    TripStayStatusChip(status: stay.status),
                    if (stay.type case final type?) TripStayTypeChip(type: type),
                  ],
                ),
              ),
              if (actions.isNotEmpty)
                PopupMenuButton<_StayAction>(
                  key: Key('stay-menu-${stay.id}'),
                  iconColor: AmaterasuColors.textSecondary,
                  color: AmaterasuColors.surfaceCard,
                  onSelected: (action) => action == _StayAction.edit
                      ? onEdit?.call()
                      : onDelete?.call(),
                  itemBuilder: (_) => [
                    for (final action in actions)
                      PopupMenuItem(
                        value: action,
                        child: Text(action == _StayAction.edit
                            ? l10n.staysEdit
                            : l10n.staysDelete),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          TripStayCardDetails(stay: stay, guestNames: guestNames),
          TripStayCardLinks(stay: stay, launch: launch),
          ?footer,
        ],
      ),
    );
  }
}
