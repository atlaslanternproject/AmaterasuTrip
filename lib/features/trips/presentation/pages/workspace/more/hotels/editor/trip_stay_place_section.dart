// Sezione "Luogo" dell'editor: nome, ricerca su Google con il modulo Luogo
// condiviso (scegliendo un risultato si compilano nome, indirizzo, città,
// paese e coordinate; telefono e sito con AmaterasuContactsAutofill) e
// campi modificabili a mano.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/places/amaterasu_contacts_autofill.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';
import 'package:amaterasutrip/core/places/widgets/amaterasu_place_search_field.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/models/trip_destination.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_validator.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
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
  final AmaterasuPlaceInfoService placeInfo;
  final VoidCallback onChanged;

  @override
  State<TripStayPlaceSection> createState() => _TripStayPlaceSectionState();
}

class _TripStayPlaceSectionState extends State<TripStayPlaceSection> {
  final _contacts = AmaterasuContactsAutofill();

  Future<void> _picked(TripDestination place) async {
    final draft = widget.draft
      ..googlePlaceId = place.placeId
      ..latitude = place.latitude
      ..longitude = place.longitude;
    draft.name.text = place.displayName;
    draft.address.text = place.formattedAddress;
    draft.city.text = place.locality ?? place.administrativeArea ?? '';
    draft.country.text = place.country ?? '';
    await _contacts.apply(
      draft.phone,
      draft.propertyUrl,
      widget.placeInfo,
      place.placeId,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    widget.onChanged();
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
        AmaterasuPlaceSearchField(
          places: widget.places,
          onPicked: _picked,
          keyPrefix: 'stay',
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
                  l10n.placesLinked,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              TextButton(onPressed: _unlink, child: Text(l10n.placesUnlink)),
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
