// Menu "⋮" della card di un soggiorno: modifica (tutti i viaggiatori) ed
// elimina (solo creatore o proprietario del viaggio). Se non c'è nessuna
// voce il menu non appare.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

enum _StayAction { edit, delete }

class TripStayCardMenu extends StatelessWidget {
  const TripStayCardMenu({
    super.key,
    required this.stayId,
    required this.canEdit,
    required this.canDelete,
    this.onEdit,
    this.onDelete,
  });

  final String stayId;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = [
      if (canEdit) _StayAction.edit,
      if (canDelete) _StayAction.delete,
    ];
    if (actions.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<_StayAction>(
      key: Key('stay-menu-$stayId'),
      iconColor: AmaterasuColors.textSecondary,
      color: AmaterasuColors.surfaceCard,
      onSelected: (action) =>
          action == _StayAction.edit ? onEdit?.call() : onDelete?.call(),
      itemBuilder: (_) => [
        for (final action in actions)
          PopupMenuItem(
            value: action,
            child: Text(action == _StayAction.edit
                ? l10n.staysEdit
                : l10n.staysDelete),
          ),
      ],
    );
  }
}
