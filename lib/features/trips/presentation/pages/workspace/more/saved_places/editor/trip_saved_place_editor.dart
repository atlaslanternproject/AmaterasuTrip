// Editor di un luogo salvato nella cornice comune delle sezioni: luogo
// cercato su Google oppure link di Google Maps incollato (da cui si
// ricavano nome e coordinate se ci sono), contatti (telefono e sito,
// compilati da Google), categoria e note, dati della visita.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/places/amaterasu_contacts_autofill.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';

import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_category.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_codec.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_place_field.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../widgets/trip_saved_place_entry.dart';
import 'trip_saved_place_draft.dart';
import 'trip_saved_place_visit_block.dart';

class TripSavedPlaceEditor extends StatefulWidget {
  const TripSavedPlaceEditor({
    super.key,
    required this.tripId,
    required this.authorUid,
    required this.places,
    required this.placeInfo,
    required this.onSave,
    this.currency = 'EUR',
    this.initial,
  });

  final String tripId;
  final String authorUid;
  final DestinationPlacesService places;
  final AmaterasuPlaceInfoService placeInfo;
  final Future<void> Function(TripSavedPlace item) onSave;

  /// Starting currency of the entry price (the trip's).
  final String currency;
  final TripSavedPlace? initial;

  @override
  State<TripSavedPlaceEditor> createState() => _TripSavedPlaceEditorState();
}

class _TripSavedPlaceEditorState extends State<TripSavedPlaceEditor>
    with TripSectionEditorSave {
  late final _draft = TripSavedPlaceDraft(
    initial: widget.initial,
    currency: widget.currency,
  );
  final _contacts = AmaterasuContactsAutofill();

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
        for (final p in const TripSavedPlaceCodec().problems(item))
          TripSectionLabels.problem(
            p,
            l10n,
            fieldLabel: (_) => l10n.savedPlaceName,
            other: (p) => p.field == 'visit'
                ? l10n.savedPlaceErrMinutes
                : l10n.restaurantErrPhone,
          ),
      ],
      save: () => widget.onSave(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = _draft;
    return TripSectionEditorFrame(
      keyPrefix: 'saved-place',
      title: d.isNew
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
              draft: d.place,
              places: widget.places,
              onChanged: _changed,
              onPicked: (place) => _contacts.apply(
                d.phone,
                d.website,
                widget.placeInfo,
                place.placeId,
                languageCode: Localizations.localeOf(context).languageCode,
              ),
            ),
            TextField(
              key: const Key('saved-place-phone'),
              controller: d.phone,
              maxLength: 40,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.restaurantPhone),
            ),
            TextField(
              key: const Key('saved-place-website'),
              controller: d.website,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: l10n.restaurantWebsite),
            ),
            TextField(
              key: const Key('saved-place-link'),
              controller: d.link,
              keyboardType: TextInputType.url,
              onChanged: (text) => setState(() => d.linkChanged(text)),
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
              selected: d.category,
              onChanged: (c) => setState(() => d.category = c ?? d.category),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('saved-place-notes'),
              controller: d.notes,
              minLines: 2,
              maxLines: 6,
              maxLength: TripSectionFields.notesMax,
              decoration: InputDecoration(labelText: l10n.sectionsNotes),
            ),
          ],
        ),
        TripSavedPlaceVisitBlock(draft: d, onChanged: _changed),
      ],
    );
  }
}
