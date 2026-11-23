// Campi di scelta riusati dagli editor delle sezioni: giorno e ora con
// pulsante "togli", scelte a etichette (una sola o nessuna) e viaggiatori
// selezionabili.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_dates.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

/// Button that picks a calendar day; with [onClear] it can be removed.
class TripSectionDayButton extends StatelessWidget {
  const TripSectionDayButton({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onClear,
    this.initial,
  });

  final String fieldKey;
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onClear;

  /// Day shown first in the calendar when there is no value.
  final DateTime? initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final day = value;
    final text = day == null
        ? l10n.sectionsDateNone
        : MaterialLocalizations.of(context).formatMediumDate(day);
    return _Picker(
      button: OutlinedButton.icon(
        key: Key(fieldKey),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: day ?? initial ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) onChanged(picked);
        },
        icon: const Icon(Icons.event_outlined, size: 18),
        label: Text('$label: $text'),
      ),
      onClear: day == null ? null : onClear,
      clearKey: '$fieldKey-clear',
    );
  }
}

/// Button that picks a time "HH:MM"; it can always be removed.
class TripSectionTimeButton extends StatelessWidget {
  const TripSectionTimeButton({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String fieldKey;
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final time = value;
    return _Picker(
      button: TextButton.icon(
        key: Key(fieldKey),
        onPressed: () async {
          final parts = (time ?? '09:00').split(':');
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            ),
          );
          if (picked == null) return;
          onChanged(
            '${picked.hour.toString().padLeft(2, '0')}:'
            '${picked.minute.toString().padLeft(2, '0')}',
          );
        },
        icon: const Icon(Icons.schedule, size: 18),
        label: Text('$label: ${time ?? l10n.sectionsTimeNone}'),
      ),
      onClear: time == null ? null : () => onChanged(null),
      clearKey: '$fieldKey-clear',
    );
  }
}

class _Picker extends StatelessWidget {
  const _Picker({required this.button, this.onClear, required this.clearKey});

  final Widget button;
  final VoidCallback? onClear;
  final String clearKey;

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      button,
      if (onClear != null)
        IconButton(
          key: Key(clearKey),
          tooltip: AppLocalizations.of(context)!.sectionsClear,
          onPressed: onClear,
          icon: const Icon(
            Icons.close,
            size: 18,
            color: AmaterasuColors.textSecondary,
          ),
        ),
    ],
  );
}

/// One choice among [values] as chips; with [allowNone] it can be removed.
class TripSectionChoices<T> extends StatelessWidget {
  const TripSectionChoices({
    super.key,
    required this.keyPrefix,
    required this.values,
    required this.codeOf,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    this.iconOf,
    this.allowNone = false,
  });

  final String keyPrefix;
  final List<T> values;
  final String Function(T value) codeOf;
  final String Function(T value) labelOf;
  final IconData Function(T value)? iconOf;
  final T? selected;
  final ValueChanged<T?> onChanged;
  final bool allowNone;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      for (final value in values)
        ChoiceChip(
          key: Key('$keyPrefix-${codeOf(value)}'),
          avatar: iconOf == null
              ? null
              : Icon(
                  iconOf!(value),
                  size: 16,
                  color: AmaterasuColors.accentBudget,
                ),
          label: Text(labelOf(value)),
          selected: selected == value,
          selectedColor: AmaterasuColors.accentBudget.withValues(alpha: 0.25),
          onSelected: (on) {
            if (on) {
              onChanged(value);
            } else if (allowNone) {
              onChanged(null);
            }
          },
        ),
    ],
  );
}

/// Trip members as chips: tap to add or remove.
class TripSectionMembers extends StatelessWidget {
  const TripSectionMembers({
    super.key,
    required this.keyPrefix,
    required this.memberNames,
    required this.selected,
    required this.onChanged,
  });

  final String keyPrefix;
  final Map<String, String> memberNames;
  final Set<String> selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      for (final entry in memberNames.entries)
        FilterChip(
          key: Key('$keyPrefix-${entry.key}'),
          label: Text(entry.value),
          selected: selected.contains(entry.key),
          selectedColor: AmaterasuColors.accentBudget.withValues(alpha: 0.25),
          onSelected: (on) {
            on ? selected.add(entry.key) : selected.remove(entry.key);
            onChanged();
          },
        ),
    ],
  );
}

/// "Wed 12 Apr 2027 · 14:30" style text for a day and optional time.
String tripSectionWhen(BuildContext context, DateTime? day, String? time) {
  if (day == null) return time ?? '';
  final date = MaterialLocalizations.of(context).formatMediumDate(day);
  return time == null ? date : '$date · $time';
}

/// Same calendar day text as saved in Firestore (YYYY-MM-DD).
String tripSectionDayCode(DateTime day) => TripStayDates.format(day);
