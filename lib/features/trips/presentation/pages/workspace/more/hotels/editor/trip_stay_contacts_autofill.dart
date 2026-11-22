// Telefono e sito presi da Google quando si sceglie il luogo nell'editor.
// Si scrivono nei campi vuoti o in quelli ancora uguali a ciò che Google
// aveva messo prima (cambiando hotel si aggiornano); quello che l'utente
// ha scritto a mano non viene mai sovrascritto. L'email resta manuale.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_validator.dart';
import 'package:amaterasutrip/features/trips/stays/places/trip_stay_place_info.dart';
import 'trip_stay_draft.dart';

class TripStayContactsAutofill {
  String? _phone;
  String? _site;

  /// Errors are ignored: contacts are a bonus, the place is already chosen.
  Future<void> apply(
    TripStayDraft draft,
    TripStayPlaceInfoService info,
    String placeId, {
    required String languageCode,
  }) async {
    TripStayPlaceContacts? found;
    try {
      found = await info.contacts(placeId, languageCode: languageCode);
    } catch (_) {
      return;
    }
    final phone = found?.phone;
    final site = found?.website;
    _phone = _fill(
      draft.phone,
      _phone,
      phone != null && TripStayValidator.isPhone(phone) ? phone : null,
    );
    _site = _fill(
      draft.propertyUrl,
      _site,
      site != null && AmaterasuWebLink.isValid(site) ? site : null,
    );
  }

  /// Writes [value] when the field is empty or still holds [previous]
  /// (Google's earlier value); returns what Google now owns in the field.
  static String? _fill(
    TextEditingController field,
    String? previous,
    String? value,
  ) {
    final current = field.text.trim();
    final fromGoogle = current.isEmpty || current == previous;
    if (!fromGoogle) return null;
    field.text = value ?? '';
    return value;
  }
}
