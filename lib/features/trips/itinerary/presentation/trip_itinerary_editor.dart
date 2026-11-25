// Editor di una voce dell'Itinerario nel pannello comune (dal basso sul
// telefono, finestra su schermo largo): blocchi a tendina Cosa, Quando,
// Dove, Previsto/fatto; "Salva" arancio e "Annulla" testuale. Restituisce
// la voce cambiata; "Salva" resta spento finché manca il titolo.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_sheet.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_itinerary_item.dart';

Future<TripItineraryItem?> editTripItineraryItem(
  BuildContext context, {
  required TripItineraryItem item,
  required List<DateTime> days,
}) => showAmaterasuSheet<TripItineraryItem>(
  context,
  builder: (_) => _Editor(item: item, days: days),
);

class _Editor extends StatefulWidget {
  const _Editor({required this.item, required this.days});

  final TripItineraryItem item;
  final List<DateTime> days;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late final _title = TextEditingController(text: widget.item.title);
  late final _time = TextEditingController(text: widget.item.time ?? '');
  late final _end = TextEditingController(text: widget.item.endTime ?? '');
  late final _zone = TextEditingController(text: widget.item.zone ?? '');
  late final _note = TextEditingController(text: widget.item.note ?? '');
  late final _actual = TextEditingController(text: widget.item.actual ?? '');
  late DateTime _day = widget.item.day;

  static final _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  @override
  void dispose() {
    for (final c in [_title, _time, _end, _zone, _note, _actual]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  void _save() {
    final i = widget.item;
    final place = i.place;
    final zone = _text(_zone);
    Navigator.pop(
      context,
      i.copyWith(
        title: _text(_title) ?? i.title,
        day: _day,
        time: () =>
            _hhmm.hasMatch(_time.text.trim()) ? _time.text.trim() : null,
        endTime: () =>
            _hhmm.hasMatch(_end.text.trim()) ? _end.text.trim() : null,
        note: () => _text(_note),
        actual: () => _text(_actual),
        place: () => place == null && zone == null
            ? null
            : TripItineraryPlace(
                name: place?.name ?? (_text(_title) ?? i.title),
                latitude: place?.latitude,
                longitude: place?.longitude,
                zone: zone,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final freeDay = widget.item.kind == TripItineraryKind.freeDay;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TripSectionBlock(
              title: l10n.itineraryBlockWhat,
              icon: Icons.edit_note_rounded,
              children: [
                TextField(
                  key: const Key('itinerary-edit-title'),
                  controller: _title,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.itineraryFieldTitle,
                  ),
                ),
                TextField(
                  controller: _note,
                  decoration: InputDecoration(
                    labelText: l10n.itineraryFieldNote,
                  ),
                ),
              ],
            ),
            TripSectionBlock(
              title: l10n.itineraryBlockWhen,
              icon: Icons.schedule_outlined,
              initiallyOpen: false,
              children: [
                TripSectionChoices<DateTime>(
                  keyPrefix: 'itinerary-edit-day',
                  values: widget.days,
                  codeOf: (d) => '${widget.days.indexOf(d) + 1}',
                  labelOf: (d) => AmaterasuDates.day(context, d),
                  selected: _day,
                  onChanged: (d) => setState(() => _day = d ?? _day),
                ),
                if (!freeDay)
                  TextField(
                    key: const Key('itinerary-edit-time'),
                    controller: _time,
                    decoration: InputDecoration(
                      labelText: l10n.itineraryFieldTime,
                    ),
                  ),
                if (!freeDay)
                  TextField(
                    key: const Key('itinerary-edit-end'),
                    controller: _end,
                    decoration: InputDecoration(
                      labelText: l10n.itineraryFieldEndTime,
                    ),
                  ),
              ],
            ),
            if (!freeDay)
              TripSectionBlock(
                title: l10n.itineraryBlockWhere,
                icon: Icons.place_outlined,
                initiallyOpen: false,
                children: [
                  TextField(
                    key: const Key('itinerary-edit-zone'),
                    controller: _zone,
                    decoration: InputDecoration(
                      labelText: l10n.itineraryFieldZone,
                    ),
                  ),
                ],
              ),
            TripSectionBlock(
              title: l10n.itineraryBlockActual,
              icon: Icons.swap_horiz_rounded,
              initiallyOpen: false,
              children: [
                TextField(
                  key: const Key('itinerary-edit-actual'),
                  controller: _actual,
                  decoration: InputDecoration(
                    labelText: l10n.itineraryFieldActual,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                AmaterasuButton.tertiary(
                  label: l10n.itineraryCancel,
                  onPressed: () => Navigator.pop(context),
                ),
                AmaterasuButton.primary(
                  key: const Key('itinerary-edit-save'),
                  label: l10n.itinerarySave,
                  // The title is required (rules).
                  onPressed: _title.text.trim().isEmpty ? null : _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
