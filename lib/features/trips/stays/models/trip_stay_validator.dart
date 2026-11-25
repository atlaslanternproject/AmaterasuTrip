// Controlli di un soggiorno con gli stessi limiti di firestore.rules:
// restituisce l'elenco dei problemi (vuoto = valido), così l'editor può
// mostrare un messaggio chiaro per ogni campo.

import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';
import 'package:amaterasutrip/core/places/amaterasu_contact_validator.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/currency_minor_units.dart';

import 'trip_stay.dart';
import 'trip_stay_booking_platform.dart';
import 'trip_stay_dates.dart';

enum TripStayProblem {
  nameMissing,
  nameTooLong,
  checkOutBeforeCheckIn,
  checkInTimeInvalid,
  checkOutTimeInvalid,
  addressTooLong,
  cityTooLong,
  countryTooLong,
  coordinatesInvalid,
  bookedViaOtherMissing,
  bookedViaOtherTooLong,
  bookingUrlInvalid,
  propertyUrlInvalid,
  phoneInvalid,
  emailInvalid,
  confirmationCodeTooLong,
  notesTooLong,
  tooManyGuests,
  expenseIdInvalid,
  costInvalid,
  directionsTooLong,
  extrasInvalid,
}

abstract final class TripStayValidator {
  static const nameMax = 200;
  static const addressMax = 300;
  static const placeMax = 150;
  static const codeMax = 100;
  static const notesMax = 10000;
  static const guestsMax = 50;
  static const directionsMax = 2000;

  /// Highest expected cost in minor units (same limit as firestore.rules).
  static const costMax = 1000000000000;
  static const phoneMax = AmaterasuContactValidator.phoneMax;
  static const emailMax = AmaterasuContactValidator.emailMax;
  static final _expenseId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  /// Same check as the shared places module (and firestore.rules).
  static bool isPhone(String value) => AmaterasuContactValidator.isPhone(value);

  static bool isEmail(String value) => AmaterasuContactValidator.isEmail(value);

  static List<TripStayProblem> problems(TripStay stay) {
    final found = <TripStayProblem>[];
    void check(bool bad, TripStayProblem problem) {
      if (bad) found.add(problem);
    }

    bool longer(String? value, int max) => (value?.length ?? 0) > max;
    bool badLink(String? value) =>
        value != null && !AmaterasuWebLink.isValid(value);

    final name = stay.name.trim();
    check(name.isEmpty, TripStayProblem.nameMissing);
    check(name.length > nameMax, TripStayProblem.nameTooLong);
    check(
      TripStayDates.nights(stay.checkInDate, stay.checkOutDate) < 0,
      TripStayProblem.checkOutBeforeCheckIn,
    );
    check(
      stay.checkInTime != null && !TripStayDates.isValidTime(stay.checkInTime),
      TripStayProblem.checkInTimeInvalid,
    );
    check(
      stay.checkOutTime != null &&
          !TripStayDates.isValidTime(stay.checkOutTime),
      TripStayProblem.checkOutTimeInvalid,
    );
    check(longer(stay.address, addressMax), TripStayProblem.addressTooLong);
    check(longer(stay.city, placeMax), TripStayProblem.cityTooLong);
    check(longer(stay.country, placeMax), TripStayProblem.countryTooLong);
    final lat = stay.latitude;
    final lng = stay.longitude;
    check(
      (lat != null && (lat < -90 || lat > 90)) ||
          (lng != null && (lng < -180 || lng > 180)),
      TripStayProblem.coordinatesInvalid,
    );
    final other = stay.bookedViaOther?.trim() ?? '';
    check(
      stay.bookedVia == TripStayBookingPlatform.other && other.isEmpty,
      TripStayProblem.bookedViaOtherMissing,
    );
    check(
      other.length > TripStayBookingPlatform.otherMaxLength,
      TripStayProblem.bookedViaOtherTooLong,
    );
    check(badLink(stay.bookingUrl), TripStayProblem.bookingUrlInvalid);
    check(badLink(stay.propertyUrl), TripStayProblem.propertyUrlInvalid);
    final phone = stay.phone;
    check(phone != null && !isPhone(phone), TripStayProblem.phoneInvalid);
    final email = stay.email;
    check(email != null && !isEmail(email), TripStayProblem.emailInvalid);
    check(
      longer(stay.confirmationCode, codeMax),
      TripStayProblem.confirmationCodeTooLong,
    );
    check(longer(stay.notes, notesMax), TripStayProblem.notesTooLong);
    check(stay.guestUids.length > guestsMax, TripStayProblem.tooManyGuests);
    final expenseId = stay.expenseId;
    check(
      expenseId != null && !_expenseId.hasMatch(expenseId),
      TripStayProblem.expenseIdInvalid,
    );
    final cost = stay.estimatedCostMinorUnits;
    check(
      cost != null &&
          (cost <= 0 ||
              cost > costMax ||
              !CurrencyMinorUnits.supportedCodes.contains(
                stay.estimatedCostCurrency,
              )),
      TripStayProblem.costInvalid,
    );
    check(
      longer(stay.directions, directionsMax),
      TripStayProblem.directionsTooLong,
    );
    check(stay.extras.invalid, TripStayProblem.extrasInvalid);
    return found;
  }
}
