// Barra sopra l'elenco degli alloggi: usa la barra dei filtri condivisa
// (pulsante "Filtri" con il numero di filtri attivi, ordine scelto e
// "Azzera filtri"), con lo stesso comportamento di prima.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/widgets/filters/amaterasu_filter_bar.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stays_filter.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripStaysFilterBar extends StatelessWidget {
  const TripStaysFilterBar({
    super.key,
    required this.filter,
    required this.shown,
    required this.total,
    required this.onOpen,
    required this.onClear,
  });

  final TripStaysFilter filter;
  final int shown;
  final int total;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmaterasuFilterBar(
      keyPrefix: 'stays',
      activeCount: filter.activeCount,
      shown: shown,
      total: total,
      onOpen: onOpen,
      onClear: onClear,
      sortLabel: filter.sort == TripStaysSort.checkInAsc
          ? l10n.staysSortAsc
          : l10n.staysSortDesc,
    );
  }
}
