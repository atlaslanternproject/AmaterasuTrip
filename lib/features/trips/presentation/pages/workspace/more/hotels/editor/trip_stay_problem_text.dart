// Messaggio chiaro, in italiano o inglese, per ogni problema trovato da
// TripStayValidator (stessi limiti di firestore.rules).

import 'package:amaterasutrip/features/trips/stays/models/trip_stay_booking_platform.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_validator.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

String tripStayProblemText(TripStayProblem problem, AppLocalizations l10n) =>
    switch (problem) {
      TripStayProblem.nameMissing => l10n.staysErrName,
      TripStayProblem.nameTooLong =>
        l10n.staysErrTooLong(TripStayValidator.nameMax),
      TripStayProblem.checkOutBeforeCheckIn => l10n.staysErrDates,
      TripStayProblem.checkInTimeInvalid ||
      TripStayProblem.checkOutTimeInvalid => l10n.staysErrTime,
      TripStayProblem.addressTooLong =>
        l10n.staysErrTooLong(TripStayValidator.addressMax),
      TripStayProblem.cityTooLong ||
      TripStayProblem.countryTooLong =>
        l10n.staysErrTooLong(TripStayValidator.placeMax),
      TripStayProblem.coordinatesInvalid => l10n.staysErrCoordinates,
      TripStayProblem.bookedViaOtherMissing => l10n.staysErrOther,
      TripStayProblem.bookedViaOtherTooLong =>
        l10n.staysErrTooLong(TripStayBookingPlatform.otherMaxLength),
      TripStayProblem.bookingUrlInvalid ||
      TripStayProblem.propertyUrlInvalid => l10n.staysErrLink,
      TripStayProblem.confirmationCodeTooLong =>
        l10n.staysErrTooLong(TripStayValidator.codeMax),
      TripStayProblem.notesTooLong =>
        l10n.staysErrTooLong(TripStayValidator.notesMax),
      TripStayProblem.tooManyGuests => l10n.staysErrGuests,
      TripStayProblem.expenseIdInvalid => l10n.staysErrExpense,
    };
