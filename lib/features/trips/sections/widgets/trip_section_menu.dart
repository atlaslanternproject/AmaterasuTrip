// Cestino di un elemento di una sezione, mostrato solo a chi può eliminare
// (creatore o proprietario del viaggio). Prima era un menu "⋮" con la sola
// voce Elimina (COERENZA G): il tocco apre la stessa doppia conferma.

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

  /// Null when the user may not delete: then the button is not shown.
  final VoidCallback? onDelete;

  /// Smaller button for the Elenco and Dettagli views.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final onDelete = this.onDelete;
    if (onDelete == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      key: Key('$keyPrefix-menu-$id'),
      tooltip: l10n.sectionsDelete,
      padding: dense ? EdgeInsets.zero : const EdgeInsets.all(8),
      iconSize: dense ? 20 : 24,
      color: AmaterasuColors.accentErrorSoft,
      icon: const Icon(Icons.delete_outline_rounded),
      onPressed: onDelete,
    );
  }
}
