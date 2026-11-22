// Apre l'editor di un soggiorno in un dialogo (largo al massimo 640 punti,
// margini ridotti sul telefono) e dice se il soggiorno è stato salvato.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'trip_stay_editor.dart';

/// Opens the editor; returns true when the stay was saved.
Future<bool> showTripStayEditor(
  BuildContext context, {
  required String tripId,
  required String authorUid,
  required Map<String, String> memberNames,
  required DestinationPlacesService places,
  required AmaterasuPlaceInfoService placeInfo,
  required Future<void> Function(TripStay stay) onSave,
  TripStay? initial,
  String defaultCurrency = 'EUR',
}) async {
  final narrow = MediaQuery.sizeOf(context).width < 600;
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: AmaterasuColors.surfaceCard,
      insetPadding: EdgeInsets.all(narrow ? 8 : 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: TripStayEditor(
          tripId: tripId,
          authorUid: authorUid,
          memberNames: memberNames,
          places: places,
          placeInfo: placeInfo,
          onSave: onSave,
          initial: initial,
          defaultCurrency: defaultCurrency,
        ),
      ),
    ),
  );
  return saved ?? false;
}
