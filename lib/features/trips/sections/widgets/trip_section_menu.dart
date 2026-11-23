// Menu "⋮" di un elemento di una sezione con la voce Elimina, mostrato
// solo a chi può eliminare (creatore o proprietario del viaggio).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripSectionMenu extends StatelessWidget {
  const TripSectionMenu({
    super.key,
    required this.keyPrefix,
    required this.id,
    required this.onDelete,
    this.dense = false,
  });

  final String keyPrefix;
  final String id;

  /// Null when the user may not delete: then the menu is not shown.
  final VoidCallback? onDelete;

  /// Smaller button for the Elenco and Dettagli views.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final onDelete = this.onDelete;
    if (onDelete == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<int>(
      key: Key('$keyPrefix-menu-$id'),
      tooltip: l10n.sectionsMore,
      padding: dense ? EdgeInsets.zero : const EdgeInsets.all(8),
      iconSize: dense ? 20 : 24,
      iconColor: AmaterasuColors.textSecondary,
      color: AmaterasuColors.surfaceCard,
      onSelected: (_) => onDelete(),
      itemBuilder: (_) => [
        PopupMenuItem(
          key: Key('$keyPrefix-delete-$id'),
          value: 0,
          child: Text(
            l10n.sectionsDelete,
            style: const TextStyle(color: AmaterasuColors.accentErrorSoft),
          ),
        ),
      ],
    );
  }
}
