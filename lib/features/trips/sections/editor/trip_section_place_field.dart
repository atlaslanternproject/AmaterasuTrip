// Campo "luogo" degli editor delle sezioni: nome scritto a mano e ricerca
// Google con il modulo Luogo condiviso; scegliendo un risultato si
// compilano nome, indirizzo, luogo Google e coordinate (scollegabile).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/places/widgets/amaterasu_place_search_field.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/models/trip_destination.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_section_fields.dart';
import '../models/trip_section_place.dart';

/// Editable place: name text plus the Google data of the chosen result.
class TripSectionPlaceDraft {
  TripSectionPlaceDraft(TripSectionPlace place)
    : name = TextEditingController(text: place.name ?? ''),
      address = place.address,
      placeId = place.placeId,
      latitude = place.latitude,
      longitude = place.longitude;

  final TextEditingController name;
  String? address;
  String? placeId;
  double? latitude;
  double? longitude;

  void pick(TripDestination place) {
    name.text = place.displayName;
    address = place.formattedAddress;
    placeId = place.placeId;
    latitude = place.latitude;
    longitude = place.longitude;
  }

  void unlink() {
    placeId = null;
    latitude = null;
    longitude = null;
  }

  TripSectionPlace toPlace() => TripSectionPlace(
    name: TripSectionFields.clean(name.text),
    address: TripSectionFields.clean(address),
    placeId: placeId,
    latitude: latitude,
    longitude: longitude,
  );

  void dispose() => name.dispose();
}

class TripSectionPlaceField extends StatelessWidget {
  const TripSectionPlaceField({
    super.key,
    required this.keyPrefix,
    required this.label,
    required this.draft,
    required this.places,
    required this.onChanged,
    this.onPicked,
  });

  final String keyPrefix;
  final String label;
  final TripSectionPlaceDraft draft;
  final DestinationPlacesService places;
  final VoidCallback onChanged;

  /// Extra work after a Google place is chosen (e.g. contacts).
  final Future<void> Function(TripDestination place)? onPicked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: Key('$keyPrefix-name'),
          controller: draft.name,
          maxLength: TripSectionPlace.nameMax,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(labelText: label),
        ),
        AmaterasuPlaceSearchField(
          places: places,
          keyPrefix: keyPrefix,
          onPicked: (place) async {
            draft.pick(place);
            await onPicked?.call(place);
            onChanged();
          },
        ),
        if (draft.placeId != null)
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
                  draft.address ?? l10n.placesLinked,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              TextButton(
                key: Key('$keyPrefix-unlink'),
                onPressed: () {
                  draft.unlink();
                  onChanged();
                },
                child: Text(l10n.placesUnlink),
              ),
            ],
          ),
      ],
    );
  }
}
