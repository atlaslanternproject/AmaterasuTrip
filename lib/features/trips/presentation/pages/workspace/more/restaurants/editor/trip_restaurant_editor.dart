// Editor di un ristorante nella cornice comune delle sezioni: luogo Google
// (compila anche telefono e sito), stato, cucina e prezzo, prenotazione,
// contatti, costo e note.

import 'package:flutter/material.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_stars.dart';

import 'package:amaterasutrip/core/places/amaterasu_contacts_autofill.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_codec.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_status.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_cost_field.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_pickers.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_place_field.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../widgets/trip_restaurant_entry.dart';
import 'trip_restaurant_draft.dart';
import 'trip_restaurant_food_block.dart';

part 'trip_restaurant_editor_parts.dart';

class TripRestaurantEditor extends StatefulWidget {
  const TripRestaurantEditor({
    super.key,
    required this.tripId,
    required this.authorUid,
    required this.places,
    required this.placeInfo,
    required this.defaultCurrency,
    required this.onSave,
    this.initial,
  });

  final String tripId;
  final String authorUid;
  final DestinationPlacesService places;
  final AmaterasuPlaceInfoService placeInfo;
  final String defaultCurrency;
  final Future<void> Function(TripRestaurant item) onSave;
  final TripRestaurant? initial;

  @override
  State<TripRestaurantEditor> createState() => _TripRestaurantEditorState();
}

class _TripRestaurantEditorState extends State<TripRestaurantEditor>
    with TripSectionEditorSave {
  late final _draft = TripRestaurantDraft(
    initial: widget.initial,
    defaultCurrency: widget.defaultCurrency,
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
        for (final p in const TripRestaurantCodec().problems(item))
          TripSectionLabels.problem(
            p,
            l10n,
            fieldLabel: (_) => l10n.restaurantName,
            other: (p) => switch (p.field) {
              'phone' => l10n.restaurantErrPhone,
              'party' => l10n.restaurantErrParty,
              'rating' => l10n.restaurantErrRating,
              _ => l10n.transportErrTime,
            },
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
      keyPrefix: 'restaurant',
      title: d.isNew
          ? l10n.restaurantEditorNewTitle
          : l10n.restaurantEditorEditTitle,
      messages: messages,
      saving: saving,
      onSave: _save,
      children: [
        TripSectionBlock(
          title: l10n.restaurantBlockPlace,
          icon: Icons.restaurant_rounded,
          children: [
            TripSectionPlaceField(
              keyPrefix: 'restaurant-place',
              label: l10n.restaurantName,
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
            _text('phone', d.phone, l10n.restaurantPhone, max: 40),
            _text('website', d.website, l10n.restaurantWebsite, max: 2048),
          ],
        ),
        _kindBlock(l10n, d),
        TripRestaurantFoodBlock(
          allergens: d.allergens,
          diets: d.diets,
          notes: d.allergenNotes,
          onChanged: _changed,
        ),
        TripSectionBlock(
          title: l10n.restaurantBlockReservation,
          icon: Icons.event_seat_outlined,
          children: [
            TripSectionDayButton(
              fieldKey: 'restaurant-day',
              label: l10n.reservationDay,
              value: d.reservationDate,
              onChanged: (v) => setState(() => d.reservationDate = v),
              onClear: () => setState(() => d.reservationDate = null),
            ),
            TripSectionTimeButton(
              fieldKey: 'restaurant-time',
              label: l10n.reservationTime,
              value: d.reservationTime,
              onChanged: (v) => setState(() => d.reservationTime = v),
            ),
            _text(
              'party',
              d.partySize,
              l10n.restaurantParty,
              max: 3,
              type: TextInputType.number,
            ),
          ],
        ),
        TripSectionBlock(
          title: l10n.sectionsBlockCost,
          icon: Icons.payments_outlined,
          children: [
            TripSectionCostField(
              keyPrefix: 'restaurant',
              draft: d.cost,
              onChanged: _changed,
            ),
          ],
        ),
        TripSectionBlock(
          title: l10n.sectionsBlockNotes,
          icon: Icons.notes_outlined,
          children: [
            _text('notes', d.notes, l10n.sectionsNotes, max: 10000, lines: 2),
          ],
        ),
      ],
    );
  }
}
