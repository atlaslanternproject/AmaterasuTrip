// "Contatta" di un alloggio: usa il pop-up condiviso del modulo Luogo con
// telefono, email e sito del soggiorno (il sito è il link dell'alloggio).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/places/widgets/amaterasu_contact_dialog.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

/// True when the stay has at least a phone, an email or a website.
bool tripStayHasContacts(TripStay stay) => amaterasuHasContacts(
  phone: stay.phone,
  email: stay.email,
  website: stay.propertyUrl,
);

Future<void> showTripStayContactDialog(
  BuildContext context,
  TripStay stay, {
  AmaterasuLaunch? launch,
}) => showAmaterasuContactDialog(
  context,
  title: AppLocalizations.of(context)!.staysContactTitle(stay.name),
  phone: stay.phone,
  email: stay.email,
  website: stay.propertyUrl,
  launch: launch,
  keyPrefix: 'stay-contact',
);
