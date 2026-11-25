// Selettore della vista di una sezione: il controllo segmentato comune
// (TripSectionSegments, stesso SegmentedButton della bucket list e degli
// alloggi) con Card, Elenco e Dettagli, scorrevole su schermo stretto.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_section_view.dart';
import 'trip_section_segments.dart';

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
    return TripSectionSegments<TripSectionView>(
      keyPrefix: keyPrefix,
      values: TripSectionView.values,
      codeOf: (v) => v.code,
      labelOf: (v) => switch (v) {
        TripSectionView.cards => l10n.sectionsViewCards,
        TripSectionView.list => l10n.sectionsViewList,
        TripSectionView.details => l10n.sectionsViewDetails,
      },
      iconOf: (v) => switch (v) {
        TripSectionView.cards => Icons.grid_view,
        TripSectionView.list => Icons.view_list,
        TripSectionView.details => Icons.table_rows,
      },
      selected: view,
      onChanged: onChanged,
    );
  }
}
