// Sezione "Luogo" dell'editor: nome, ricerca su Google come nella bucket
// list (scegliendo un risultato si compilano nome, indirizzo, città, paese
// e coordinate; telefono e sito con TripStayContactsAutofill) e campi
// modificabili a mano.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/models/trip_destination.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_validator.dart';
import 'package:amaterasutrip/features/trips/stays/places/trip_stay_place_info.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_contacts_autofill.dart';
import 'trip_stay_draft.dart';
import 'trip_stay_editor_section.dart';

class TripStayPlaceSection extends StatefulWidget {
  const TripStayPlaceSection({
    super.key,
    required this.draft,
    required this.places,
    required this.placeInfo,
    required this.onChanged,
  });

  final TripStayDraft draft;
  final DestinationPlacesService places;
  final TripStayPlaceInfoService placeInfo;
  final VoidCallback onChanged;

  @override
  State<TripStayPlaceSection> createState() => _TripStayPlaceSectionState();
}

class _TripStayPlaceSectionState extends State<TripStayPlaceSection> {
  final _search = TextEditingController();
  List<DestinationPrediction>? _results;
  String? _error;
  bool _busy = false;
  final _contacts = TripStayContactsAutofill();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _language => Localizations.localeOf(context).languageCode;

  Future<void> _find() async {
    final l10n = AppLocalizations.of(context)!;
    if (_search.text.trim().length < 2 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _results = null;
    });
    try {
      final found = await widget.places.search(
        _search.text,
        languageCode: _language,
      );
      if (mounted) setState(() => _results = found);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.staysSearchError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _select(DestinationPrediction prediction) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final place = await widget.places.getDetails(
        prediction.placeId,
        languageCode: _language,
      );
      final draft = widget.draft
        ..googlePlaceId = place.placeId
        ..latitude = place.latitude
        ..longitude = place.longitude;
      draft.name.text = place.displayName;
      draft.address.text = place.formattedAddress;
      draft.city.text = place.locality ?? place.administrativeArea ?? '';
      draft.country.text = place.country ?? '';
      await _contacts.apply(
        draft,
        widget.placeInfo,
        place.placeId,
        languageCode: _language,
      );
      _search.clear();
      _results = null;
      widget.onChanged();
    } catch (_) {
      _error = l10n.staysPlaceLoadError;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _unlink() {
    widget.draft
      ..googlePlaceId = null
      ..latitude = null
      ..longitude = null;
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = widget.draft;
    final results = _results;
    return TripStayEditorSection(
      title: l10n.staysSectionPlace,
      icon: Icons.place_outlined,
      children: [
        TextField(
          key: const Key('stay-name'),
          controller: draft.name,
          maxLength: TripStayValidator.nameMax,
          onChanged: (_) => widget.onChanged(),
          decoration: InputDecoration(labelText: l10n.staysName),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('stay-search'),
                controller: _search,
                onSubmitted: (_) => _find(),
                decoration: InputDecoration(labelText: l10n.staysSearchHint),
              ),
            ),
            IconButton(
              key: const Key('stay-search-go'),
              tooltip: l10n.staysSearchButton,
              onPressed: _busy ? null : _find,
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Text(
            _error!,
            style: const TextStyle(color: AmaterasuColors.accentErrorSoft),
          ),
        if (results != null && results.isEmpty)
          Text(
            l10n.staysNoResults,
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
        if (draft.googlePlaceId != null)
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 16,
                color: AmaterasuColors.success,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.staysPlaceLinked,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: _unlink,
                child: Text(l10n.staysPlaceUnlink),
              ),
            ],
          ),
        TextField(
          controller: draft.address,
          maxLength: TripStayValidator.addressMax,
          decoration: InputDecoration(labelText: l10n.staysAddress),
        ),
        TextField(
          controller: draft.city,
          maxLength: TripStayValidator.placeMax,
          decoration: InputDecoration(labelText: l10n.staysCity),
        ),
        TextField(
          controller: draft.country,
          maxLength: TripStayValidator.placeMax,
          decoration: InputDecoration(labelText: l10n.staysCountry),
        ),
      ],
    );
  }
}
