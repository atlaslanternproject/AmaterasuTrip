// Barra sopra l'elenco di una sezione: gruppi di filtri come etichette
// selezionabili (stato, tipo, periodo, ordine…) scorrevoli in orizzontale
// e il selettore della vista. Ricorda la vista scelta sul dispositivo.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import '../data/trip_section_view_preferences.dart';
import '../models/trip_section_view.dart';
import 'trip_section_view_selector.dart';

/// One row of choices; [selected] is the code of the chosen option.
class TripSectionFilterGroup {
  const TripSectionFilterGroup({
    required this.id,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String id;
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelected;
}

class TripSectionToolbar extends StatelessWidget {
  const TripSectionToolbar({
    super.key,
    required this.keyPrefix,
    required this.groups,
    required this.view,
    required this.onView,
  });

  final String keyPrefix;
  final List<TripSectionFilterGroup> groups;
  final TripSectionView view;
  final ValueChanged<TripSectionView> onView;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final group in groups)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    for (final (code, label) in group.options)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          key: Key('$keyPrefix-filter-${group.id}-$code'),
                          label: Text(label),
                          selected: group.selected == code,
                          selectedColor: AmaterasuColors.accentBudget
                              .withValues(alpha: 0.25),
                          onSelected: (_) => group.onSelected(code),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            TripSectionViewSelector(
              keyPrefix: keyPrefix,
              view: view,
              onChanged: onView,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Loads and saves the chosen view of [section] for this user and trip.
mixin TripSectionViewMemory<W extends StatefulWidget> on State<W> {
  TripSectionView view = TripSectionView.cards;

  String get viewSection;
  String get viewTripId;
  String? get viewUid;

  @override
  void initState() {
    super.initState();
    final uid = viewUid;
    if (uid == null) return;
    TripSectionViewPreferences.load(viewSection, uid, viewTripId).then((saved) {
      if (saved != null && mounted) setState(() => view = saved);
    });
  }

  void changeView(TripSectionView value) {
    setState(() => view = value);
    final uid = viewUid;
    if (uid != null) {
      TripSectionViewPreferences.save(viewSection, uid, viewTripId, value);
    }
  }
}
