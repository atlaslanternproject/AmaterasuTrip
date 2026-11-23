// Testi e icone dei trasporti: nome e icona del tipo, fuso orario
// ("UTC+09:00"), durata leggibile e titolo di un trasporto (tipo con
// compagnia e numero).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_type.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

abstract final class TripTransportLabels {
  static String type(TripTransportType type, AppLocalizations l10n) =>
      switch (type) {
        TripTransportType.flight => l10n.transportTypeFlight,
        TripTransportType.train => l10n.transportTypeTrain,
        TripTransportType.bus => l10n.transportTypeBus,
        TripTransportType.ferry => l10n.transportTypeFerry,
        TripTransportType.carRental => l10n.transportTypeCarRental,
        TripTransportType.transfer => l10n.transportTypeTransfer,
        TripTransportType.other => l10n.transportTypeOther,
      };

  static IconData icon(TripTransportType type) => switch (type) {
    TripTransportType.flight => Icons.flight_rounded,
    TripTransportType.train => Icons.train_rounded,
    TripTransportType.bus => Icons.directions_bus_rounded,
    TripTransportType.ferry => Icons.directions_boat_rounded,
    TripTransportType.carRental => Icons.car_rental_rounded,
    TripTransportType.transfer => Icons.airport_shuttle_rounded,
    TripTransportType.other => Icons.commute_rounded,
  };

  /// "Volo · ITA Airways AZ 792" (only the type when there is no company).
  static String title(TripTransport item, AppLocalizations l10n) {
    final service = [item.carrier, item.number].whereType<String>().join(' ');
    return [
      type(item.type, l10n),
      service,
    ].where((part) => part.isNotEmpty).join(' · ');
  }

  static String offset(String offset) => 'UTC$offset';

  /// "2 h 05 min".
  static String duration(int minutes) {
    final hours = minutes ~/ 60;
    final rest = (minutes % 60).toString().padLeft(2, '0');
    return hours == 0 ? '$minutes min' : '$hours h $rest min';
  }

  /// Offsets offered in the editor, from UTC-12:00 to UTC+14:00.
  static const offsets = [
    '-12:00',
    '-11:00',
    '-10:00',
    '-09:30',
    '-09:00',
    '-08:00',
    '-07:00',
    '-06:00',
    '-05:00',
    '-04:00',
    '-03:30',
    '-03:00',
    '-02:00',
    '-01:00',
    '+00:00',
    '+01:00',
    '+02:00',
    '+03:00',
    '+03:30',
    '+04:00',
    '+04:30',
    '+05:00',
    '+05:30',
    '+05:45',
    '+06:00',
    '+06:30',
    '+07:00',
    '+08:00',
    '+08:45',
    '+09:00',
    '+09:30',
    '+10:00',
    '+10:30',
    '+11:00',
    '+12:00',
    '+12:45',
    '+13:00',
    '+14:00',
  ];
}
