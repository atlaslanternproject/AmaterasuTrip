// Conversione dei soggiorni da e verso i dati Firestore. I campi facoltativi
// vuoti non vengono salvati; createdAt e updatedAt li aggiunge il repository
// con l'ora del server (come chiede firestore.rules).

import 'trip_stay.dart';
import 'trip_stay_amenity.dart';
import 'trip_stay_booking_platform.dart';
import 'trip_stay_dates.dart';
import 'trip_stay_status.dart';
import 'trip_stay_type.dart';

abstract final class TripStayCodec {
  /// Fields to save, without createdAt and updatedAt.
  static Map<String, dynamic> toMap(TripStay stay) {
    String? text(String? value) {
      final trimmed = value?.trim() ?? '';
      return trimmed.isEmpty ? null : trimmed;
    }

    final other = stay.bookedVia == TripStayBookingPlatform.other
        ? text(stay.bookedViaOther)
        : null;
    final cost = stay.estimatedCostCurrency == null
        ? null
        : stay.estimatedCostMinorUnits;
    final cancellation = stay.freeCancellationUntil;

    return {
      'tripId': stay.tripId,
      'name': stay.name.trim(),
      'checkInDate': TripStayDates.format(stay.checkInDate),
      'checkOutDate': TripStayDates.format(stay.checkOutDate),
      'status': stay.status.code,
      'createdByUid': stay.createdByUid,
      'type': ?stay.type?.code,
      'checkInTime': ?text(stay.checkInTime),
      'checkOutTime': ?text(stay.checkOutTime),
      'address': ?text(stay.address),
      'city': ?text(stay.city),
      'country': ?text(stay.country),
      'googlePlaceId': ?text(stay.googlePlaceId),
      'latitude': ?stay.latitude,
      'longitude': ?stay.longitude,
      'bookedVia': ?stay.bookedVia?.code,
      'bookedViaOther': ?other,
      'bookingUrl': ?text(stay.bookingUrl),
      'propertyUrl': ?text(stay.propertyUrl),
      'phone': ?text(stay.phone),
      'email': ?text(stay.email),
      'confirmationCode': ?text(stay.confirmationCode),
      'notes': ?text(stay.notes),
      if (stay.guestUids.isNotEmpty) 'guestUids': List.of(stay.guestUids),
      'expenseId': ?text(stay.expenseId),
      if (cost != null) ...{
        'estimatedCostMinorUnits': cost,
        'estimatedCostCurrency': stay.estimatedCostCurrency,
      },
      if (cancellation != null)
        'freeCancellationUntil': TripStayDates.format(cancellation),
      if (stay.amenities.isNotEmpty)
        'amenities': [
          for (final a in TripStayAmenity.values)
            if (stay.amenities.contains(a)) a.code,
        ],
      'directions': ?text(stay.directions),
    };
  }

  /// Stay from a Firestore document; throws FormatException when the
  /// required fields are missing or invalid.
  static TripStay fromMap(String id, Map<String, dynamic> data) {
    String? text(String key) {
      final value = data[key];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    double? number(String key) {
      final value = data[key];
      return value is num ? value.toDouble() : null;
    }

    DateTime? time(String key) {
      final value = data[key];
      if (value is DateTime) return value;
      try {
        return (value as dynamic)?.toDate() as DateTime?;
      } catch (_) {
        return null;
      }
    }

    final checkIn = TripStayDates.parse(data['checkInDate']);
    final checkOut = TripStayDates.parse(data['checkOutDate']);
    final status = TripStayStatus.fromCode(data['status']);
    final name = text('name');
    final tripId = text('tripId');
    final author = text('createdByUid');
    if (checkIn == null ||
        checkOut == null ||
        status == null ||
        name == null ||
        tripId == null ||
        author == null) {
      throw FormatException('Invalid stay $id.');
    }

    final guests = data['guestUids'];
    final cost = data['estimatedCostMinorUnits'];
    final currency = text('estimatedCostCurrency');
    final hasCost = cost is int && currency != null;
    return TripStay(
      id: id,
      tripId: tripId,
      name: name,
      checkInDate: checkIn,
      checkOutDate: checkOut,
      status: status,
      createdByUid: author,
      type: TripStayType.fromCode(data['type']),
      createdAt: time('createdAt'),
      updatedAt: time('updatedAt'),
      checkInTime: text('checkInTime'),
      checkOutTime: text('checkOutTime'),
      address: text('address'),
      city: text('city'),
      country: text('country'),
      googlePlaceId: text('googlePlaceId'),
      latitude: number('latitude'),
      longitude: number('longitude'),
      bookedVia: TripStayBookingPlatform.fromCode(data['bookedVia']),
      bookedViaOther: text('bookedViaOther'),
      bookingUrl: text('bookingUrl'),
      propertyUrl: text('propertyUrl'),
      phone: text('phone'),
      email: text('email'),
      confirmationCode: text('confirmationCode'),
      notes: text('notes'),
      guestUids: guests is List
          ? guests.whereType<String>().toList()
          : const [],
      expenseId: text('expenseId'),
      estimatedCostMinorUnits: hasCost ? cost : null,
      estimatedCostCurrency: hasCost ? currency : null,
      freeCancellationUntil: TripStayDates.parse(data['freeCancellationUntil']),
      amenities: TripStayAmenity.fromCodes(data['amenities']),
      directions: text('directions'),
    );
  }
}
