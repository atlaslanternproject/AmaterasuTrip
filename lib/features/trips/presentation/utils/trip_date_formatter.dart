import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formats a trip calendar date with an explicit year.
///
/// Uses the application's language (Italian or English).
/// This is presentation-only: the stored DateTime is unchanged.
String formatTripDateWithYear(DateTime date, Locale locale) {
  return DateFormat.yMMMd(locale.languageCode).format(date);
}
