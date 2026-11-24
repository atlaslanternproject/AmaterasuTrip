// Blocco "Posti, check-in e noleggio" dell'editor dei trasporti: per ogni
// passeggero due caselle (Lettera e Posto), ore di apertura del check-in e
// link, minuti per arrivare in aeroporto; per il noleggio carburante e
// franchigia.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_extras.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_type.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

/// Editable copy of [TripTransportExtras].
class TripTransportExtrasDraft {
  TripTransportExtrasDraft(TripTransportExtras extras)
    : _seats = {
        for (final e in extras.seats.entries)
          e.key: (
            TextEditingController(text: e.value.letter ?? ''),
            TextEditingController(text: e.value.seat ?? ''),
          ),
      },
      checkInHours = TextEditingController(
        text: extras.checkInHoursBefore?.toString() ?? '',
      ),
      checkInUrl = TextEditingController(text: extras.checkInUrl ?? ''),
      airportMinutes = TextEditingController(
        text: extras.airportMinutesBefore?.toString() ?? '',
      ),
      fuel = TextEditingController(text: extras.fuelPolicy ?? ''),
      deductible = TextEditingController(text: extras.deductible ?? '');

  final Map<String, (TextEditingController, TextEditingController)> _seats;
  final TextEditingController checkInHours;
  final TextEditingController checkInUrl;
  final TextEditingController airportMinutes;
  final TextEditingController fuel;
  final TextEditingController deductible;

  (TextEditingController, TextEditingController) seatOf(String uid) =>
      _seats.putIfAbsent(
        uid,
        () => (TextEditingController(), TextEditingController()),
      );

  TripTransportExtras toExtras(Set<String> passengers) {
    String? clean(TextEditingController c) => TripSectionFields.clean(c.text);
    int? number(TextEditingController c) {
      final text = clean(c);
      return text == null ? null : (int.tryParse(text) ?? -1);
    }

    return TripTransportExtras(
      seats: {
        for (final uid in passengers)
          if (_seats[uid] case final seat?)
            uid: TripTransportSeat(
              letter: clean(seat.$1),
              seat: clean(seat.$2),
            ),
      },
      checkInHoursBefore: number(checkInHours),
      checkInUrl: clean(checkInUrl),
      airportMinutesBefore: number(airportMinutes),
      fuelPolicy: clean(fuel),
      deductible: clean(deductible),
    );
  }

  void dispose() {
    for (final (a, b) in _seats.values) {
      a.dispose();
      b.dispose();
    }
    for (final c in [
      checkInHours,
      checkInUrl,
      airportMinutes,
      fuel,
      deductible,
    ]) {
      c.dispose();
    }
  }
}

class TripTransportExtrasBlock extends StatelessWidget {
  const TripTransportExtrasBlock({
    super.key,
    required this.draft,
    required this.type,
    required this.passengers,
    required this.memberNames,
  });

  final TripTransportExtrasDraft draft;
  final TripTransportType type;
  final Set<String> passengers;
  final Map<String, String> memberNames;

  Widget _field(
    String key,
    TextEditingController c,
    String label, {
    bool number = false,
  }) => TextField(
    key: Key('transport-$key'),
    controller: c,
    keyboardType: number ? TextInputType.number : null,
    maxLength: number ? 3 : TripTransportExtras.textMax,
    decoration: InputDecoration(labelText: label, counterText: ''),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final flight = type == TripTransportType.flight;
    return TripSectionBlock(
      title: l10n.transportBlockExtras,
      icon: Icons.event_seat_outlined,
      initiallyOpen: false,
      children: [
        for (final uid in passengers) ...[
          Text(memberNames[uid] ?? uid),
          Row(
            children: [
              Expanded(
                child: _field(
                  'seat-letter-$uid',
                  draft.seatOf(uid).$1,
                  l10n.transportSeatLetter,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  'seat-number-$uid',
                  draft.seatOf(uid).$2,
                  l10n.transportSeatNumber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        _field(
          'checkin-hours',
          draft.checkInHours,
          flight
              ? l10n.transportCheckInHoursFlight
              : l10n.transportCheckInHours,
          number: true,
        ),
        TextField(
          key: const Key('transport-checkin-url'),
          controller: draft.checkInUrl,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: l10n.transportCheckInLink),
        ),
        _field(
          'airport-minutes',
          draft.airportMinutes,
          flight
              ? l10n.transportAirportMinutesFlight
              : l10n.transportAirportMinutes,
          number: true,
        ),
        if (type == TripTransportType.carRental) ...[
          _field('fuel', draft.fuel, l10n.transportFuel),
          _field('deductible', draft.deductible, l10n.transportDeductible),
        ],
      ],
    );
  }
}
