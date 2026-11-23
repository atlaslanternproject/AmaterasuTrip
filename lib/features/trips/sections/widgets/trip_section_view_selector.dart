// Selettore della vista di una sezione: stesso SegmentedButton della
// bucket list e degli alloggi (Card, Elenco, Dettagli, stesse icone),
// scorrevole in orizzontale su schermo stretto.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_section_view.dart';

class TripSectionViewSelector extends StatelessWidget {
  const TripSectionViewSelector({
    super.key,
    required this.keyPrefix,
    required this.view,
    required this.onChanged,
  });

  final String keyPrefix;
  final TripSectionView view;
  final ValueChanged<TripSectionView> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      key: Key('$keyPrefix-view'),
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<TripSectionView>(
        segments: [
          ButtonSegment(
            value: TripSectionView.cards,
            label: Text(l10n.sectionsViewCards),
            icon: const Icon(Icons.grid_view),
          ),
          ButtonSegment(
            value: TripSectionView.list,
            label: Text(l10n.sectionsViewList),
            icon: const Icon(Icons.view_list),
          ),
          ButtonSegment(
            value: TripSectionView.details,
            label: Text(l10n.sectionsViewDetails),
            icon: const Icon(Icons.table_rows),
          ),
        ],
        selected: {view},
        onSelectionChanged: (values) => onChanged(values.first),
      ),
    );
  }
}
