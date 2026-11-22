// Elenco degli alloggi con filtri: tiene i filtri scelti (finché la pagina
// è aperta) e la modalità di visualizzazione (ricordata sul dispositivo),
// mostra la barra "Filtri", il selettore Card/Elenco/Dettagli, l'elenco
// filtrato e ordinato, oppure uno stato vuoto se nessuno corrisponde.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/data/trip_stays_view_preferences.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stays_filter.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stays_view.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stays_empty.dart';
import 'trip_stays_filter_bar.dart';
import 'trip_stays_filter_sheet.dart';
import 'trip_stays_view_selector.dart';

class TripStaysFilteredView extends StatefulWidget {
  const TripStaysFilteredView({
    super.key,
    required this.stays,
    required this.today,
    required this.listOf,
    required this.tripId,
    this.uid,
  });

  final String tripId;

  /// Signed-in user: the chosen view is remembered for them and the trip.
  final String? uid;

  final List<TripStay> stays;
  final DateTime today;

  /// Builds the list for the stays to show (already filtered and sorted).
  final Widget Function(List<TripStay> shown, TripStaysView view) listOf;

  @override
  State<TripStaysFilteredView> createState() => _TripStaysFilteredViewState();
}

class _TripStaysFilteredViewState extends State<TripStaysFilteredView> {
  var _filter = const TripStaysFilter();
  var _view = TripStaysView.cards;

  @override
  void initState() {
    super.initState();
    final uid = widget.uid;
    if (uid == null) return;
    TripStaysViewPreferences.load(uid, widget.tripId)
        .then((view) {
          if (view != null && mounted) setState(() => _view = view);
        })
        .catchError((Object _) {});
  }

  void _setView(TripStaysView view) {
    setState(() => _view = view);
    final uid = widget.uid;
    if (uid != null) {
      TripStaysViewPreferences.save(
        uid,
        widget.tripId,
        view,
      ).catchError((Object _) {});
    }
  }

  void _set(TripStaysFilter filter) {
    if (mounted) setState(() => _filter = filter);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shown = _filter.apply(widget.stays, widget.today);
    return Column(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TripStaysFilterBar(
                filter: _filter,
                shown: shown.length,
                total: widget.stays.length,
                onOpen: () => showTripStaysFilterSheet(
                  context,
                  initial: _filter,
                  onChanged: _set,
                ),
                onClear: () => _set(_filter.cleared()),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TripStaysViewSelector(view: _view, onChanged: _setView),
              ),
            ),
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? TripStaysEmpty(
                  boxKey: const Key('stays-no-match'),
                  icon: Icons.filter_alt_off_outlined,
                  title: l10n.staysNoMatchTitle,
                  body: l10n.staysNoMatchBody,
                  actionKey: const Key('stays-no-match-clear'),
                  actionIcon: Icons.close_rounded,
                  actionLabel: l10n.staysFiltersClear,
                  onAction: () => _set(_filter.cleared()),
                )
              : widget.listOf(shown, _view),
        ),
      ],
    );
  }
}
