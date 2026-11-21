// Editor di un soggiorno (creazione e modifica) in un dialogo largo al
// massimo 640 punti: sezioni luogo, tipo, contatti, date, stato, prenotazione, ospiti e
// note; al salvataggio mostra i problemi trovati con messaggi chiari.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_validator.dart';
import 'package:amaterasutrip/features/trips/stays/places/trip_stay_place_info.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_booking_section.dart';
import 'trip_stay_contacts_section.dart';
import 'trip_stay_dates_section.dart';
import 'trip_stay_draft.dart';
import 'trip_stay_guests_notes_sections.dart';
import 'trip_stay_place_section.dart';
import 'trip_stay_problem_text.dart';
import 'trip_stay_status_section.dart';
import 'trip_stay_type_section.dart';

/// Opens the editor; returns true when the stay was saved.
Future<bool> showTripStayEditor(
  BuildContext context, {
  required String tripId,
  required String authorUid,
  required Map<String, String> memberNames,
  required DestinationPlacesService places,
  required TripStayPlaceInfoService placeInfo,
  required Future<void> Function(TripStay stay) onSave,
  TripStay? initial,
}) async {
  final narrow = MediaQuery.sizeOf(context).width < 600;
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: AmaterasuColors.surfaceCard,
      insetPadding: EdgeInsets.all(narrow ? 8 : 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: TripStayEditor(
          tripId: tripId,
          authorUid: authorUid,
          memberNames: memberNames,
          places: places,
          placeInfo: placeInfo,
          onSave: onSave,
          initial: initial,
        ),
      ),
    ),
  );
  return saved ?? false;
}

class TripStayEditor extends StatefulWidget {
  const TripStayEditor({
    super.key,
    required this.tripId,
    required this.authorUid,
    required this.memberNames,
    required this.places,
    required this.placeInfo,
    required this.onSave,
    this.initial,
  });

  final String tripId;
  final String authorUid;
  final Map<String, String> memberNames;
  final DestinationPlacesService places;
  final TripStayPlaceInfoService placeInfo;
  final Future<void> Function(TripStay stay) onSave;
  final TripStay? initial;

  @override
  State<TripStayEditor> createState() => _TripStayEditorState();
}

class _TripStayEditorState extends State<TripStayEditor> {
  late final _draft = TripStayDraft(initial: widget.initial, today: DateTime.now());
  List<String> _messages = const [];
  bool _saving = false;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final stay = _draft.toStay(tripId: widget.tripId, authorUid: widget.authorUid);
    final problems = TripStayValidator.problems(stay);
    if (problems.isNotEmpty) {
      setState(() => _messages =
          problems.map((p) => tripStayProblemText(p, l10n)).toSet().toList());
      return;
    }
    setState(() {
      _saving = true;
      _messages = const [];
    });
    try {
      await widget.onSave(stay);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _messages = [l10n.staysSaveError]);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Text(
            _draft.isNew ? l10n.staysEditorNewTitle : l10n.staysEditorEditTitle,
            style: const TextStyle(color: AmaterasuColors.textPrimary,
                fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TripStayPlaceSection(draft: _draft, places: widget.places,
                    placeInfo: widget.placeInfo, onChanged: _changed),
                TripStayTypeSection(draft: _draft, onChanged: _changed),
                TripStayContactsSection(draft: _draft, onChanged: _changed),
                TripStayDatesSection(draft: _draft, onChanged: _changed),
                TripStayStatusSection(draft: _draft, onChanged: _changed),
                TripStayBookingSection(draft: _draft, onChanged: _changed),
                TripStayGuestsSection(
                    draft: _draft, memberNames: widget.memberNames, onChanged: _changed),
                TripStayNotesSection(draft: _draft),
              ],
            ),
          ),
        ),
        for (final message in _messages)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(message, key: const Key('stay-editor-error'),
                style: const TextStyle(color: AmaterasuColors.accentErrorSoft, fontSize: 13)),
          ),
        if (_saving) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context, false),
                child: Text(l10n.staysCancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('stay-save'),
                style: FilledButton.styleFrom(backgroundColor: AmaterasuColors.accentBudget),
                onPressed: _saving ? null : _save,
                child: Text(l10n.staysSave),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
