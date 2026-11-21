// Controlli di un soggiorno con gli stessi limiti di firestore.rules:
// restituisce l'elenco dei problemi (vuoto = valido), così l'editor può
// mostrare un messaggio chiaro per ogni campo.

import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';

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
}

abstract final class TripStayValidator {
  static const nameMax = 200;
  static const addressMax = 300;
  static const placeMax = 150;
  static const codeMax = 100;
  static const notesMax = 10000;
  static const guestsMax = 50;
  static const phoneMax = 40;
  static const emailMax = 254;
  static final _expenseId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  // Same patterns as firestore.rules (validStay).
  static final _phone = RegExp(r'^[+]?[0-9 ()./-]{4,40}$');
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+[.][^\s@]+$');

  /// Digits, spaces, + ( ) . / - ; at most [phoneMax] characters.
  static bool isPhone(String value) =>
      value.length <= phoneMax && _phone.hasMatch(value);

  /// Basic check: something@domain.tld, at most [emailMax] characters.
  static bool isEmail(String value) =>
      value.length <= emailMax && _email.hasMatch(value);

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
    check(longer(stay.confirmationCode, codeMax),
        TripStayProblem.confirmationCodeTooLong);
    check(longer(stay.notes, notesMax), TripStayProblem.notesTooLong);
    check(stay.guestUids.length > guestsMax, TripStayProblem.tooManyGuests);
    final expenseId = stay.expenseId;
    check(
      expenseId != null && !_expenseId.hasMatch(expenseId),
      TripStayProblem.expenseIdInvalid,
    );
    return found;
  }
}
