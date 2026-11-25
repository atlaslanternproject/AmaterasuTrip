// Impalcatura comune delle pagine delle sezioni del viaggio: intestazione
// con indietro, titolo e "+" (come Hotel e alloggi), eventuali schede e
// corpo con caricamento, errore, stato vuoto oppure il contenuto; si
// ridisegna quando cambiano le scelte di Aspetto (formati di data e ora).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_appearance_provider.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_section_empty.dart';

class TripSectionScaffold<T> extends ConsumerWidget {
  const TripSectionScaffold({
    super.key,
    required this.tripId,
    required this.keyPrefix,
    required this.title,
    required this.addLabel,
    required this.onAdd,
    required this.items,
    required this.emptyIcon,
    required this.emptyText,
    required this.body,
    this.top,
  });

  final String tripId;
  final String keyPrefix;
  final String title;
  final String addLabel;
  final VoidCallback onAdd;
  final AsyncValue<List<T>> items;
  final IconData emptyIcon;
  final String emptyText;
  final Widget Function(List<T> items) body;

  /// Shown above the content and the empty state (e.g. tabs).
  final Widget? top;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Redraw when the appearance choices change (date and time formats).
    ref.watch(amaterasuAppearanceProvider);
    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
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
                  IconButton.filled(
                    key: Key('$keyPrefix-add'),
                    tooltip: addLabel,
                    style: IconButton.styleFrom(
                      backgroundColor: AmaterasuColors.accentBudget,
                    ),
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            ?top,
            Expanded(
              child: items.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Text(
                    l10n.sectionsLoadError,
                    style: const TextStyle(
                      color: AmaterasuColors.textSecondary,
                    ),
                  ),
                ),
                data: (list) => list.isEmpty
                    ? TripSectionEmpty(
                        keyPrefix: keyPrefix,
                        icon: emptyIcon,
                        text: emptyText,
                        addLabel: addLabel,
                        onAdd: onAdd,
                      )
                    : body(list),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
