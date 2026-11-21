// Sezione "Date e orari" dell'editor: giorni di check-in e check-out (il
// check-out non può essere prima del check-in) e orari facoltativi.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_dates.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_draft.dart';
import 'trip_stay_editor_section.dart';

class TripStayDatesSection extends StatelessWidget {
  const TripStayDatesSection({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final TripStayDraft draft;
  final VoidCallback onChanged;

  Future<void> _pickDay(BuildContext context, bool checkIn) async {
    final first = checkIn ? DateTime(2000) : draft.checkInDate;
    final current = checkIn ? draft.checkInDate : draft.checkOutDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(first) ? first : current,
      firstDate: first,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    if (checkIn) {
      draft.checkInDate = picked;
      if (draft.checkOutDate.isBefore(picked)) {
        draft.checkOutDate = picked.add(const Duration(days: 1));
      }
    } else {
      draft.checkOutDate = picked;
    }
    onChanged();
  }

  Future<void> _pickTime(BuildContext context, bool checkIn) async {
    final current = checkIn ? draft.checkInTime : draft.checkOutTime;
    final parts = (current ?? (checkIn ? '15:00' : '10:00')).split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (picked == null) return;
    final text = '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    checkIn ? draft.checkInTime = text : draft.checkOutTime = text;
    onChanged();
  }

  void _clearTime(bool checkIn) {
    checkIn ? draft.checkInTime = null : draft.checkOutTime = null;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = MaterialLocalizations.of(context).formatMediumDate;
    Widget row(bool checkIn) {
      final time = checkIn ? draft.checkInTime : draft.checkOutTime;
      final day = checkIn ? draft.checkInDate : draft.checkOutDate;
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            key: Key(checkIn ? 'stay-checkin-day' : 'stay-checkout-day'),
            onPressed: () => _pickDay(context, checkIn),
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Text('${checkIn ? l10n.staysCheckInDay : l10n.staysCheckOutDay}: ${format(day)}'),
          ),
          TextButton.icon(
            key: Key(checkIn ? 'stay-checkin-time' : 'stay-checkout-time'),
            onPressed: () => _pickTime(context, checkIn),
            icon: const Icon(Icons.schedule, size: 18),
            label: Text(time == null
                ? '${checkIn ? l10n.staysCheckInTime : l10n.staysCheckOutTime}: ${l10n.staysTimeNone}'
                : '${checkIn ? l10n.staysCheckInTime : l10n.staysCheckOutTime}: $time'),
          ),
          if (time != null)
            IconButton(
              tooltip: l10n.staysTimeClear,
              onPressed: () => _clearTime(checkIn),
              icon: const Icon(Icons.close, size: 18, color: AmaterasuColors.textSecondary),
            ),
        ],
      );
    }

    return TripStayEditorSection(
      title: l10n.staysSectionDates,
      icon: Icons.date_range_outlined,
      children: [
        row(true),
        const SizedBox(height: 6),
        row(false),
        const SizedBox(height: 6),
        Text(
          l10n.staysNights(TripStayDates.nights(draft.checkInDate, draft.checkOutDate)),
          style: const TextStyle(color: AmaterasuColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}
