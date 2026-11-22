// Selettore della modalità di visualizzazione degli alloggi: stesso
// SegmentedButton della bucket list, con gli stessi nomi (Card, Elenco,
// Dettagli) e le stesse icone, scorrevole in orizzontale su schermo stretto.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/stays/models/trip_stays_view.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

// TODO(audit): la bucket list ha la sua copia di questo selettore (bucket_method_page_view.dart, testi _t); unificarli in un componente condiviso.
class TripStaysViewSelector extends StatelessWidget {
  const TripStaysViewSelector({
    super.key,
    required this.view,
    required this.onChanged,
  });

  final TripStaysView view;
  final ValueChanged<TripStaysView> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      key: const Key('stays-view'),
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<TripStaysView>(
        segments: [
          ButtonSegment(
            value: TripStaysView.cards,
            label: Text(l10n.staysViewCards),
            icon: const Icon(Icons.grid_view),
          ),
          ButtonSegment(
            value: TripStaysView.list,
            label: Text(l10n.staysViewList),
            icon: const Icon(Icons.view_list),
          ),
          ButtonSegment(
            value: TripStaysView.details,
            label: Text(l10n.staysViewDetails),
            icon: const Icon(Icons.table_rows),
          ),
        ],
        selected: {view},
        onSelectionChanged: (values) => onChanged(values.first),
      ),
    );
  }
}
