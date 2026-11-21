// Testi e colori di Hotel/Alloggi: nome dello stato e della piattaforma di
// prenotazione, colore dello stato (token del tema), date leggibili.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_booking_platform.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

abstract final class TripStayLabels {
  static String status(TripStayStatus status, AppLocalizations l10n) =>
      switch (status) {
        TripStayStatus.booked => l10n.staysStatusBooked,
        TripStayStatus.toConfirm => l10n.staysStatusToConfirm,
        TripStayStatus.cancelled => l10n.staysStatusCancelled,
      };

  /// Booked = green (success), to confirm = gold, cancelled = muted.
  static Color statusColor(TripStayStatus status) => switch (status) {
    TripStayStatus.booked => AmaterasuColors.success,
    TripStayStatus.toConfirm => AmaterasuColors.accentGold,
    TripStayStatus.cancelled => AmaterasuColors.textMuted,
  };

  static String platform(
    TripStayBookingPlatform platform,
    AppLocalizations l10n,
  ) => switch (platform) {
    TripStayBookingPlatform.booking => l10n.staysPlatformBooking,
    TripStayBookingPlatform.airbnb => l10n.staysPlatformAirbnb,
    TripStayBookingPlatform.propertySite => l10n.staysPlatformPropertySite,
    TripStayBookingPlatform.agency => l10n.staysPlatformAgency,
    TripStayBookingPlatform.other => l10n.staysPlatformOther,
  };

  /// "Prenotato su …", with the free text for "other".
  static String? bookedVia(TripStay stay, AppLocalizations l10n) {
    final via = stay.bookedVia;
    if (via == null) return null;
    final name = via == TripStayBookingPlatform.other
        ? (stay.bookedViaOther ?? platform(via, l10n))
        : platform(via, l10n);
    return l10n.staysBookedVia(name);
  }

  /// Day, plus the time when known (e.g. "12 apr 2027 · 15:00").
  static String day(BuildContext context, DateTime day, String? time) {
    final text = MaterialLocalizations.of(context).formatMediumDate(day);
    return time == null ? text : '$text · $time';
  }
}
