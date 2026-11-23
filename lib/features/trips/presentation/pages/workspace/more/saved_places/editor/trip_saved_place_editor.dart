// Editor di un luogo salvato nella cornice comune delle sezioni: luogo
// cercato su Google oppure link di Google Maps incollato (da cui si
// ricavano nome e coordinate se ci sono), categoria e note.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_maps_link.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_category.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_codec.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_place_field.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../widgets/trip_saved_place_entry.dart';

class TripSavedPlaceEditor extends StatefulWidget {
  const TripSavedPlaceEditor({
    super.key,
    required this.tripId,
    required this.authorUid,
    required this.places,
    required this.onSave,
    this.initial,
  });

  final String tripId;
  final String authorUid;
  final DestinationPlacesService places;
  final Future<void> Function(TripSavedPlace item) onSave;
  final TripSavedPlace? initial;

  @override
  State<TripSavedPlaceEditor> createState() => _TripSavedPlaceEditorState();
}

class _TripSavedPlaceEditorState extends State<TripSavedPlaceEditor>
    with TripSectionEditorSave {
  late final _place = TripSectionPlaceDraft(
    (widget.initial?.place ?? const TripSectionPlace()).withName(
      widget.initial?.name,
    ),
  );
  late final _link = TextEditingController(text: widget.initial?.mapsUrl);
  late final _notes = TextEditingController(text: widget.initial?.notes);
  late var _category = widget.initial?.category ?? TripSavedPlaceCategory.sight;

  @override
  void dispose() {
    _place.dispose();
    _link.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// A pasted Google Maps link fills the empty name and the coordinates.
  void _linkChanged(String text) {
    if (TripMapsLink.isMapsLink(text)) {
      final link = TripMapsLink.parse(text);
      if (_place.name.text.trim().isEmpty && link.name != null) {
        _place.name.text = link.name!;
      }
      if (_place.placeId == null && link.latitude != null) {
        _place
          ..latitude = link.latitude
          ..longitude = link.longitude;
      }
    }
    setState(() {});
  }

  Future<void> _save() {
    final l10n = AppLocalizations.of(context)!;
    final initial = widget.initial;
    final item = TripSavedPlace(
      id: initial?.id ?? '',
      tripId: widget.tripId,
      createdByUid: initial?.createdByUid ?? widget.authorUid,
      name: _place.name.text.trim(),
      category: _category,
      place: _place.toPlace(),
      mapsUrl: TripSectionFields.clean(_link.text),
      notes: TripSectionFields.clean(_notes.text),
    );
    return saveWith(
      problems: [
        for (final p in const TripSavedPlaceCodec().problems(item))
          TripSectionLabels.problem(
            p,
            l10n,
            fieldLabel: (_) => l10n.savedPlaceName,
          ),
      ],
      save: () => widget.onSave(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TripSectionEditorFrame(
      keyPrefix: 'saved-place',
      title: widget.initial == null
          ? l10n.savedPlaceEditorNewTitle
          : l10n.savedPlaceEditorEditTitle,
      messages: messages,
      saving: saving,
      onSave: _save,
      children: [
        TripSectionBlock(
          title: l10n.savedPlaceBlockPlace,
          icon: Icons.place_outlined,
          children: [
            TripSectionPlaceField(
              keyPrefix: 'saved-place',
              label: l10n.savedPlaceName,
              draft: _place,
              places: widget.places,
              onChanged: () => setState(() {}),
            ),
            TextField(
              key: const Key('saved-place-link'),
              controller: _link,
              keyboardType: TextInputType.url,
              onChanged: _linkChanged,
              decoration: InputDecoration(
                labelText: l10n.savedPlaceMapsLink,
                helperText: l10n.savedPlaceMapsLinkHint,
                helperMaxLines: 2,
              ),
            ),
          ],
        ),
        TripSectionBlock(
          title: l10n.savedPlaceBlockCategory,
          icon: Icons.category_outlined,
          children: [
            TripSectionChoices<TripSavedPlaceCategory>(
              keyPrefix: 'saved-place-category',
              values: TripSavedPlaceCategory.values,
              codeOf: (c) => c.code,
              labelOf: (c) => TripSavedPlaceLabels.category(c, l10n),
              iconOf: TripSavedPlaceLabels.icon,
              selected: _category,
              onChanged: (c) => setState(() => _category = c ?? _category),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('saved-place-notes'),
              controller: _notes,
              minLines: 2,
              maxLines: 6,
              maxLength: TripSectionFields.notesMax,
              decoration: InputDecoration(labelText: l10n.sectionsNotes),
            ),
          ],
        ),
      ],
    );
  }
}
