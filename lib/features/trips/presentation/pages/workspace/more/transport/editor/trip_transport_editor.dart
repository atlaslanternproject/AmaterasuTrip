// Editor di un trasporto (creazione e modifica) nella cornice comune delle
// sezioni: blocchi tipo e stato, da/a, partenza e arrivo, compagnia e
// passeggeri, prenotazione, costo e note (blocchi nel file part).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_cost_field.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_pickers.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_place_field.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_problem.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_codec.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_type.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../widgets/trip_transport_labels.dart';
import 'trip_transport_draft.dart';
import 'trip_transport_extras_block.dart';

part 'trip_transport_editor_blocks.dart';

class TripTransportEditor extends StatefulWidget {
  const TripTransportEditor({
    super.key,
    required this.tripId,
    required this.authorUid,
    required this.memberNames,
    required this.places,
    required this.defaultCurrency,
    required this.onSave,
    this.initial,
  });

  final String tripId;
  final String authorUid;
  final Map<String, String> memberNames;
  final DestinationPlacesService places;
  final String defaultCurrency;
  final Future<void> Function(TripTransport item) onSave;
  final TripTransport? initial;

  @override
  State<TripTransportEditor> createState() => _TripTransportEditorState();
}

class _TripTransportEditorState extends State<TripTransportEditor>
    with TripSectionEditorSave {
  late final _draft = TripTransportDraft(
    initial: widget.initial,
    today: DateTime.now(),
    defaultCurrency: widget.defaultCurrency,
  );

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  String _problemText(TripSectionProblem problem, AppLocalizations l10n) =>
      TripSectionLabels.problem(
        problem,
        l10n,
        fieldLabel: (field) => field,
        other: (p) => switch (p.field) {
          'arrivalBeforeDeparture' => l10n.transportErrArrival,
          'departureOffset' || 'arrivalOffset' => l10n.transportErrTimeZone,
          'seats' ||
          'checkInHours' ||
          'airportMinutes' => l10n.transportErrExtras,
          _ => l10n.transportErrTime,
        },
      );

  Future<void> _save() {
    final l10n = AppLocalizations.of(context)!;
    final item = _draft.toItem(
      tripId: widget.tripId,
      authorUid: widget.authorUid,
    );
    return saveWith(
      problems: [
        for (final p in const TripTransportCodec().problems(item))
          _problemText(p, l10n),
      ],
      save: () => widget.onSave(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TripSectionEditorFrame(
      keyPrefix: 'transport',
      title: _draft.isNew
          ? l10n.transportEditorNewTitle
          : l10n.transportEditorEditTitle,
      messages: messages,
      saving: saving,
      onSave: _save,
      children: [
        _typeBlock(l10n),
        _routeBlock(l10n),
        _timesBlock(l10n),
        _serviceBlock(l10n),
        _bookingBlock(l10n),
        TripTransportExtrasBlock(
          draft: _draft.extras,
          type: _draft.type,
          passengers: _draft.passengers,
          memberNames: widget.memberNames,
        ),
        TripSectionBlock(
          title: l10n.sectionsBlockCost,
          icon: Icons.payments_outlined,
          children: [
            TripSectionCostField(
              keyPrefix: 'transport',
              draft: _draft.cost,
              onChanged: _changed,
            ),
          ],
        ),
        TripSectionBlock(
          title: l10n.sectionsBlockNotes,
          icon: Icons.notes_outlined,
          children: [
            TextField(
              key: const Key('transport-notes'),
              controller: _draft.notes,
              minLines: 2,
              maxLines: 6,
              maxLength: 10000,
              decoration: InputDecoration(labelText: l10n.sectionsNotes),
            ),
          ],
        ),
      ],
    );
  }
}
