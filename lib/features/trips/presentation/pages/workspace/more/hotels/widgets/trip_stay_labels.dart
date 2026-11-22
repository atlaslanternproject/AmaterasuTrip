// Testi e colori di Hotel/Alloggi: nome dello stato, del tipo di alloggio
// (con la sua icona) e della piattaforma di prenotazione, colore dello
// stato (token del tema) e periodo breve del soggiorno.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_booking_platform.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_type.dart';
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

  static String type(TripStayType type, AppLocalizations l10n) =>
      switch (type) {
        TripStayType.hotel => l10n.staysTypeHotel,
        TripStayType.bnb => l10n.staysTypeBnb,
        TripStayType.apartment => l10n.staysTypeApartment,
        TripStayType.hostel => l10n.staysTypeHostel,
        TripStayType.camping => l10n.staysTypeCamping,
        TripStayType.other => l10n.staysTypeOther,
      };

  static IconData typeIcon(TripStayType? type) => switch (type) {
    TripStayType.hotel || null => Icons.hotel_rounded,
    TripStayType.bnb => Icons.free_breakfast_rounded,
    TripStayType.apartment => Icons.apartment_rounded,
    TripStayType.hostel => Icons.bed_rounded,
    TripStayType.camping => Icons.cabin_rounded,
    TripStayType.other => Icons.home_work_rounded,
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

  /// Short period with nights, e.g. "12 apr – 15 apr 2027 · 3 notti".
  static String period(BuildContext context, TripStay stay) {
    final dates = MaterialLocalizations.of(context);
    final nights = AppLocalizations.of(context)!.staysNights(stay.nights);
    return '${dates.formatShortMonthDay(stay.checkInDate)} – '
        '${dates.formatMediumDate(stay.checkOutDate)} · $nights';
  }
}
