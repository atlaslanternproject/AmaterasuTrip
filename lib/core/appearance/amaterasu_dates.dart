// Date e ore come le vuole l'utente (Impostazioni > Aspetto, Extra E4):
// "come la lingua" (formati di Material, come prima), 30/08/2027,
// 08/30/2027, 2027-08-30, 2027/08/30 o "30 agosto 2027"; ore a 24 o a 12
// ore. Le stesse funzioni scrivono l'esempio delle scelte in Aspetto. Usato dalle sezioni nuove; nei moduli
// approvati si applicherà dopo l'ok su COERENZA.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'amaterasu_appearance.dart';
import 'amaterasu_appearance_provider.dart';

abstract final class AmaterasuDates {
  static AmaterasuAppearance _appearance(BuildContext context) {
    try {
      return ProviderScope.containerOf(
        context,
        listen: false,
      ).read(amaterasuAppearanceProvider);
    } catch (_) {
      // Outside the app (some tests): the language formats, as before.
      return const AmaterasuAppearance();
    }
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// The calendar day; [full] uses the long form when it follows the
  /// language (e.g. "lunedì 12 aprile 2027").
  static String day(BuildContext context, DateTime d, {bool full = false}) =>
      withFormat(context, _appearance(context).dateFormat, d, full: full);

  /// [d] written with one of AmaterasuAppearance.dateFormats (also the
  /// example of each choice in Appearance).
  static String withFormat(
    BuildContext context,
    String format,
    DateTime d, {
    bool full = false,
  }) {
    final dd = _two(d.day), mm = _two(d.month);
    String long() {
      final tag = Localizations.localeOf(context).toLanguageTag();
      return (full ? DateFormat.yMMMMEEEEd(tag) : DateFormat.yMMMMd(tag))
          .format(d);
    }

    return switch (format) {
      'dmy' => '$dd/$mm/${d.year}',
      'mdy' => '$mm/$dd/${d.year}',
      'ymd' => '${d.year}-$mm-$dd',
      'ymdSlash' => '${d.year}/$mm/$dd',
      'long' => long(),
      _ =>
        full
            ? MaterialLocalizations.of(context).formatFullDate(d)
            : MaterialLocalizations.of(context).formatMediumDate(d),
    };
  }

  /// A saved "HH:mm" time; "2:05 PM" with the 12-hour format.
  static String time(BuildContext context, String hhmm) {
    if (_appearance(context).timeFormat != '12') return hhmm;
    final parts = hhmm.split(':');
    final h = parts.length == 2 ? int.tryParse(parts[0]) : null;
    if (h == null) return hhmm;
    final suffix = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${parts[1]} $suffix';
  }
}
