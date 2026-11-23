// Editor di una prenotazione nella cornice comune delle sezioni: nome,
// categoria e stato; data, ora e luogo Google; codice, link e
// partecipanti; regole di cancellazione; costo; note.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_category.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_codec.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_cost_field.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_pickers.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_place_field.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../widgets/trip_reservation_entry.dart';
import 'trip_reservation_draft.dart';

class TripReservationEditor extends StatefulWidget {
  const TripReservationEditor({
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
  final Future<void> Function(TripReservation item) onSave;
  final TripReservation? initial;

  @override
  State<TripReservationEditor> createState() => _TripReservationEditorState();
}

class _TripReservationEditorState extends State<TripReservationEditor>
    with TripSectionEditorSave {
  late final _draft = TripReservationDraft(
    initial: widget.initial,
    defaultCurrency: widget.defaultCurrency,
  );

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  Future<void> _save() {
    final l10n = AppLocalizations.of(context)!;
    final item = _draft.toItem(
      tripId: widget.tripId,
      authorUid: widget.authorUid,
    );
    return saveWith(
      problems: [
        for (final p in const TripReservationCodec().problems(item))
          TripSectionLabels.problem(
            p,
            l10n,
            fieldLabel: (_) => l10n.reservationName,
            other: (_) => l10n.transportErrTime,
          ),
      ],
      save: () => widget.onSave(item),
    );
  }

  Widget _text(
    String key,
    TextEditingController c,
    String label,
    int max, {
    int lines = 1,
  }) => TextField(
    key: Key('reservation-$key'),
    controller: c,
    minLines: lines,
    maxLines: lines == 1 ? 1 : lines + 3,
    maxLength: max,
    decoration: InputDecoration(labelText: label),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = _draft;
    return TripSectionEditorFrame(
      keyPrefix: 'reservation',
      title: d.isNew
          ? l10n.reservationEditorNewTitle
          : l10n.reservationEditorEditTitle,
      messages: messages,
      saving: saving,
      onSave: _save,
      children: [
        TripSectionBlock(
          title: l10n.reservationBlockMain,
          icon: Icons.confirmation_number_outlined,
          children: [
            _text('name', d.name, l10n.reservationName, 200),
            TripSectionChoices<TripReservationCategory>(
              keyPrefix: 'reservation-category',
              values: TripReservationCategory.values,
              codeOf: (c) => c.code,
              labelOf: (c) => TripReservationLabels.category(c, l10n),
              iconOf: TripReservationLabels.icon,
              selected: d.category,
              onChanged: (c) => setState(() => d.category = c ?? d.category),
            ),
            const SizedBox(height: 12),
            TripSectionChoices<TripBookingStatus>(
              keyPrefix: 'reservation-status',
              values: TripBookingStatus.values,
              codeOf: (s) => s.code,
              labelOf: (s) => TripSectionLabels.status(s, l10n),
              selected: d.status,
              onChanged: (s) => setState(() => d.status = s ?? d.status),
            ),
          ],
        ),
        TripSectionBlock(
          title: l10n.reservationBlockWhenWhere,
          icon: Icons.event_outlined,
          children: [
            TripSectionDayButton(
              fieldKey: 'reservation-day',
              label: l10n.reservationDay,
              value: d.date,
              onChanged: (v) => setState(() => d.date = v),
              onClear: () => setState(() => d.date = null),
            ),
            TripSectionTimeButton(
              fieldKey: 'reservation-time',
              label: l10n.reservationTime,
              value: d.time,
              onChanged: (v) => setState(() => d.time = v),
            ),
            const SizedBox(height: 8),
            TripSectionPlaceField(
              keyPrefix: 'reservation-place',
              label: l10n.reservationPlace,
              draft: d.place,
              places: widget.places,
              onChanged: _changed,
            ),
          ],
        ),
        TripSectionBlock(
          title: l10n.reservationBlockBooking,
          icon: Icons.receipt_outlined,
          children: [
            _text('code', d.bookingCode, l10n.sectionsBookingCode, 100),
            _text('url', d.bookingUrl, l10n.reservationLink, 2048),
            Text(l10n.reservationParticipants),
            const SizedBox(height: 6),
            TripSectionMembers(
              keyPrefix: 'reservation-participant',
              memberNames: widget.memberNames,
              selected: d.participants,
              onChanged: _changed,
            ),
            const SizedBox(height: 12),
            _text('policy', d.policy, l10n.reservationPolicy, 2000, lines: 2),
          ],
        ),
        TripSectionBlock(
          title: l10n.sectionsBlockCost,
          icon: Icons.payments_outlined,
          children: [
            TripSectionCostField(
              keyPrefix: 'reservation',
              draft: d.cost,
              onChanged: _changed,
            ),
          ],
        ),
        TripSectionBlock(
          title: l10n.sectionsBlockNotes,
          icon: Icons.notes_outlined,
          children: [
            _text('notes', d.notes, l10n.sectionsNotes, 10000, lines: 2),
          ],
        ),
      ],
    );
  }
}
