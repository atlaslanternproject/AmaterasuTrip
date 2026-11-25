// Ricerca di un luogo Google per gli editor (alloggi e altre sezioni): campo
// di ricerca, pulsante, risultati e messaggi. Scegliendo un risultato carica
// i dettagli e li passa a [onPicked], che compila i campi della sezione.

import 'package:amaterasutrip/core/widgets/common/amaterasu_loader.dart';
import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/models/trip_destination.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class AmaterasuPlaceSearchField extends StatefulWidget {
  const AmaterasuPlaceSearchField({
    super.key,
    required this.places,
    required this.onPicked,
    this.keyPrefix = 'place',
  });

  final DestinationPlacesService places;

  /// Called with the chosen place; the field shows progress meanwhile.
  final Future<void> Function(TripDestination place) onPicked;

  /// Start of the keys (e.g. "stay" gives "stay-search", "stay-search-go").
  final String keyPrefix;

  @override
  State<AmaterasuPlaceSearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<AmaterasuPlaceSearchField> {
  final _search = TextEditingController();
  List<DestinationPrediction>? _results;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _language => Localizations.localeOf(context).languageCode;

  Future<void> _run(Future<void> Function() task, String errorText) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await task();
    } catch (_) {
      if (mounted) setState(() => _error = errorText);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _find() async {
    if (_search.text.trim().length < 2 || _busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _results = null);
    await _run(() async {
      final found = await widget.places.search(
        _search.text,
        languageCode: _language,
      );
      if (mounted) setState(() => _results = found);
    }, l10n.placesSearchError);
  }

  Future<void> _select(DestinationPrediction prediction) => _run(() async {
    final place = await widget.places.getDetails(
      prediction.placeId,
      languageCode: _language,
    );
    await widget.onPicked(place);
    _search.clear();
    _results = null;
  }, AppLocalizations.of(context)!.placesLoadError);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final results = _results;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: Key('${widget.keyPrefix}-search'),
                controller: _search,
                onSubmitted: (_) => _find(),
                decoration: InputDecoration(labelText: l10n.placesSearchHint),
              ),
            ),
            IconButton(
              key: Key('${widget.keyPrefix}-search-go'),
              tooltip: l10n.placesSearchButton,
              onPressed: _busy ? null : _find,
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        if (_busy) const AmaterasuLoader(),
        if (_error != null)
          Text(
            _error!,
            style: const TextStyle(color: AmaterasuColors.accentErrorSoft),
          ),
        if (results != null && results.isEmpty)
          Text(
            l10n.placesNoResults,
            style: const TextStyle(color: AmaterasuColors.textSecondary),
          ),
        for (final result in results ?? const <DestinationPrediction>[])
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.place,
                color: AmaterasuColors.accentBudget,
              ),
              title: Text(result.primaryText),
              subtitle: Text(result.secondaryText),
              onTap: () => _select(result),
            ),
          ),
      ],
    );
  }
}
