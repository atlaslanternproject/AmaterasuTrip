// Modello di un soggiorno del viaggio (Hotel/Alloggi): nome, date e orari,
// stato, tipo di alloggio, contatti, luogo Google, prenotazione (piattaforma, link, codice), note,
// ospiti e spesa del budget collegata. Le regole sono in TripStayValidator.

import 'trip_stay_booking_platform.dart';
import 'trip_stay_dates.dart';
import 'trip_stay_status.dart';
import 'trip_stay_type.dart';

class TripStay {
  const TripStay({
    this.id = '',
    required this.tripId,
    required this.name,
    required this.checkInDate,
    required this.checkOutDate,
    this.status = TripStayStatus.toConfirm,
    this.type,
    required this.createdByUid,
    this.createdAt,
    this.updatedAt,
    this.checkInTime,
    this.checkOutTime,
    this.address,
    this.city,
    this.country,
    this.googlePlaceId,
    this.latitude,
    this.longitude,
    this.bookedVia,
    this.bookedViaOther,
    this.bookingUrl,
    this.propertyUrl,
    this.phone,
    this.email,
    this.confirmationCode,
    this.notes,
    this.guestUids = const [],
    this.expenseId,
  });

  /// Firestore document ID; empty before the first save.
  final String id;
  final String tripId;
  final String name;

  /// Calendar days (time of day ignored).
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final TripStayStatus status;

  /// Kind of place (hotel, B&B…), optional.
  final TripStayType? type;
  final String createdByUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// "HH:MM", optional.
  final String? checkInTime;
  final String? checkOutTime;

  final String? address;
  final String? city;
  final String? country;
  final String? googlePlaceId;
  final double? latitude;
  final double? longitude;

  final TripStayBookingPlatform? bookedVia;

  /// Free text when [bookedVia] is "other".
  final String? bookedViaOther;
  final String? bookingUrl;
  final String? propertyUrl;

  /// Contacts of the place, optional (the website is [propertyUrl]).
  final String? phone;
  final String? email;
  final String? confirmationCode;
  final String? notes;

  /// Trip members who sleep there.
  final List<String> guestUids;

  /// Linked shared expense of the budget, if any.
  final String? expenseId;

  int get nights => TripStayDates.nights(checkInDate, checkOutDate);

  bool get isActive => status.isActive;

  /// Both active and with at least one night in common. A check-out on
  /// the same day as the other check-in is not an overlap.
  bool overlaps(TripStay other) =>
      isActive &&
      other.isActive &&
      checkInDate.isBefore(other.checkOutDate) &&
      other.checkInDate.isBefore(checkOutDate);

  bool get hasMap =>
      (googlePlaceId?.trim().isNotEmpty ?? false) ||
      (latitude != null && longitude != null);

  TripStay copyWith({
    String? id,
    TripStayStatus? status,
    String? expenseId,
  }) => TripStay(
    id: id ?? this.id,
    tripId: tripId,
    name: name,
    checkInDate: checkInDate,
    checkOutDate: checkOutDate,
    status: status ?? this.status,
    type: type,
    createdByUid: createdByUid,
    createdAt: createdAt,
    updatedAt: updatedAt,
    checkInTime: checkInTime,
    checkOutTime: checkOutTime,
    address: address,
    city: city,
    country: country,
    googlePlaceId: googlePlaceId,
    latitude: latitude,
    longitude: longitude,
    bookedVia: bookedVia,
    bookedViaOther: bookedViaOther,
    bookingUrl: bookingUrl,
    propertyUrl: propertyUrl,
    phone: phone,
    email: email,
    confirmationCode: confirmationCode,
    notes: notes,
    guestUids: guestUids,
    expenseId: expenseId ?? this.expenseId,
  );
}
