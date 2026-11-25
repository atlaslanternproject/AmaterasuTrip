// Dettagli aggiunti ai trasporti nella 1.27.0: posto per passeggero
// (lettera/carrozza e numero), apertura del check-in online e link,
// anticipo per arrivare in aeroporto, carburante e franchigia del noleggio.

import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_problem.dart';

class TripTransportSeat {
  const TripTransportSeat({this.letter, this.seat});

  /// Letter or coach (e.g. "C" or "Carrozza 5") and seat number.
  final String? letter;
  final String? seat;

  bool get isEmpty => letter == null && seat == null;

  /// "C · 12A" or just one of the two.
  String get label => [letter, seat].whereType<String>().join(' · ');
}

class TripTransportExtras {
  const TripTransportExtras({
    this.seats = const {},
    this.checkInHoursBefore,
    this.checkInUrl,
    this.airportMinutesBefore,
    this.fuelPolicy,
    this.deductible,
    this.departureZone,
    this.departureCity,
    this.arrivalZone,
    this.arrivalCity,
  });

  static const textMax = 60;
  static const seatMax = 20;
  static const checkInHoursMax = 168;
  static const airportMinutesMax = 600;

  /// Passenger uid -> seat.
  final Map<String, TripTransportSeat> seats;

  /// Online check-in opens this many hours before departure (flights: 24).
  final int? checkInHoursBefore;
  final String? checkInUrl;

  /// Be at the airport this many minutes before departure (flights: 120).
  final int? airportMinutesBefore;

  /// Car rental: fuel policy and deductible, free text.
  final String? fuelPolicy;
  final String? deductible;

  /// Time zones chosen by city (IANA, e.g. Europe/Rome) and the city shown;
  /// the offsets of the transport are computed from them (Extra C).
  final String? departureZone;
  final String? departureCity;
  final String? arrivalZone;
  final String? arrivalCity;

  static final zonePattern = RegExp(r'^[A-Za-z0-9_+/-]{1,64}$');

  TripTransportExtras withZones({
    required String? departureZone,
    required String? departureCity,
    required String? arrivalZone,
    required String? arrivalCity,
  }) => TripTransportExtras(
    seats: seats,
    checkInHoursBefore: checkInHoursBefore,
    checkInUrl: checkInUrl,
    airportMinutesBefore: airportMinutesBefore,
    fuelPolicy: fuelPolicy,
    deductible: deductible,
    departureZone: departureZone,
    departureCity: departureCity,
    arrivalZone: arrivalZone,
    arrivalCity: arrivalCity,
  );

  /// Saved together in the "extras" map of the transport document.
  static const keys = ['extras'];

  Map<String, dynamic> toMap() {
    String? clean(String? v) => TripSectionFields.clean(v);
    final saved = {
      for (final e in seats.entries)
        if (!e.value.isEmpty)
          e.key: {
            'letter': ?clean(e.value.letter),
            'seat': ?clean(e.value.seat),
          },
    };
    final map = {
      if (saved.isNotEmpty) 'seatsByPassenger': saved,
      'checkInHoursBefore': ?checkInHoursBefore,
      'checkInUrl': ?clean(checkInUrl),
      'airportMinutesBefore': ?airportMinutesBefore,
      'fuelPolicy': ?clean(fuelPolicy),
      'deductible': ?clean(deductible),
      'departureZone': ?clean(departureZone),
      'departureCity': ?clean(departureCity),
      'arrivalZone': ?clean(arrivalZone),
      'arrivalCity': ?clean(arrivalCity),
    };
    return map.isEmpty ? const {} : {'extras': map};
  }

  static TripTransportExtras fromMap(Map<String, dynamic> document) {
    final nested = document['extras'];
    final data = nested is Map
        ? Map<String, dynamic>.from(nested)
        : const <String, dynamic>{};
    String? text(String key) => TripSectionFields.readText(data, key);
    int? number(String key) => data[key] is int ? data[key] as int : null;
    final raw = data['seatsByPassenger'];
    return TripTransportExtras(
      seats: {
        if (raw is Map)
          for (final e in raw.entries)
            if (e.key is String && e.value is Map)
              e.key as String: TripTransportSeat(
                letter: (e.value as Map)['letter'] is String
                    ? (e.value as Map)['letter'] as String
                    : null,
                seat: (e.value as Map)['seat'] is String
                    ? (e.value as Map)['seat'] as String
                    : null,
              ),
      },
      checkInHoursBefore: number('checkInHoursBefore'),
      checkInUrl: text('checkInUrl'),
      airportMinutesBefore: number('airportMinutesBefore'),
      fuelPolicy: text('fuelPolicy'),
      deductible: text('deductible'),
      departureZone: text('departureZone'),
      departureCity: text('departureCity'),
      arrivalZone: text('arrivalZone'),
      arrivalCity: text('arrivalCity'),
    );
  }

  void check(TripSectionChecks c) {
    const other = TripSectionProblemKind.other;
    final hours = checkInHoursBefore;
    final minutes = airportMinutesBefore;
    c
      ..maxLength(fuelPolicy, textMax, 'fuelPolicy')
      ..maxLength(deductible, textMax, 'deductible')
      ..maxLength(departureCity, TripSectionFields.shortMax, 'departureCity')
      ..maxLength(arrivalCity, TripSectionFields.shortMax, 'arrivalCity')
      ..check(
        [
          departureZone,
          arrivalZone,
        ].any((z) => z != null && !zonePattern.hasMatch(z)),
        other,
        'zone',
      )
      ..check(
        seats.length > TripSectionFields.uidsMax ||
            seats.values.any(
              (s) =>
                  (s.letter?.length ?? 0) > seatMax ||
                  (s.seat?.length ?? 0) > seatMax,
            ),
        other,
        'seats',
      )
      ..check(
        hours != null && (hours < 0 || hours > checkInHoursMax),
        other,
        'checkInHours',
      )
      ..check(
        minutes != null && (minutes < 0 || minutes > airportMinutesMax),
        other,
        'airportMinutes',
      )
      ..check(
        TripSectionFields.badLink(checkInUrl),
        TripSectionProblemKind.link,
        'checkInUrl',
      );
  }
}
