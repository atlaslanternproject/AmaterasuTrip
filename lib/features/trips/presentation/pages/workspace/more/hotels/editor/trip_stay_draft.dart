// Stato modificabile dell'editor di un soggiorno: campi di testo, date,
// orari, stato, tipo, piattaforma, luogo Google e ospiti. Si crea da un soggiorno
// esistente (o vuoto) e si trasforma in TripStay per salvarlo.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_booking_platform.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_type.dart';

class TripStayDraft {
  TripStayDraft({TripStay? initial, required DateTime today})
    : _initial = initial,
      name = TextEditingController(text: initial?.name ?? ''),
      address = TextEditingController(text: initial?.address ?? ''),
      city = TextEditingController(text: initial?.city ?? ''),
      country = TextEditingController(text: initial?.country ?? ''),
      bookedViaOther = TextEditingController(
        text: initial?.bookedViaOther ?? '',
      ),
      bookingUrl = TextEditingController(text: initial?.bookingUrl ?? ''),
      propertyUrl = TextEditingController(text: initial?.propertyUrl ?? ''),
      confirmationCode = TextEditingController(
        text: initial?.confirmationCode ?? '',
      ),
      notes = TextEditingController(text: initial?.notes ?? ''),
      checkInDate = initial?.checkInDate ?? DateUtils.dateOnly(today),
      checkOutDate =
          initial?.checkOutDate ??
          DateUtils.dateOnly(today).add(const Duration(days: 1)),
      checkInTime = initial?.checkInTime,
      checkOutTime = initial?.checkOutTime,
      status = initial?.status ?? TripStayStatus.toConfirm,
      type = initial?.type,
      bookedVia = initial?.bookedVia,
      googlePlaceId = initial?.googlePlaceId,
      latitude = initial?.latitude,
      longitude = initial?.longitude,
      guestUids = {...?initial?.guestUids};

  final TripStay? _initial;
  final TextEditingController name;
  final TextEditingController address;
  final TextEditingController city;
  final TextEditingController country;
  final TextEditingController bookedViaOther;
  final TextEditingController bookingUrl;
  final TextEditingController propertyUrl;
  final TextEditingController confirmationCode;
  final TextEditingController notes;

  DateTime checkInDate;
  DateTime checkOutDate;
  String? checkInTime;
  String? checkOutTime;
  TripStayStatus status;
  TripStayType? type;
  TripStayBookingPlatform? bookedVia;
  String? googlePlaceId;
  double? latitude;
  double? longitude;
  final Set<String> guestUids;

  bool get isNew => _initial == null;

  /// The stay to save. New stays belong to [authorUid].
  TripStay toStay({required String tripId, required String authorUid}) {
    String? text(TextEditingController controller) {
      final value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    final initial = _initial;
    return TripStay(
      id: initial?.id ?? '',
      tripId: tripId,
      name: name.text.trim(),
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      status: status,
      type: type,
      createdByUid: initial?.createdByUid ?? authorUid,
      createdAt: initial?.createdAt,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      address: text(address),
      city: text(city),
      country: text(country),
      googlePlaceId: googlePlaceId,
      latitude: latitude,
      longitude: longitude,
      bookedVia: bookedVia,
      bookedViaOther: bookedVia == TripStayBookingPlatform.other
          ? text(bookedViaOther)
          : null,
      bookingUrl: text(bookingUrl),
      propertyUrl: text(propertyUrl),
      confirmationCode: text(confirmationCode),
      notes: text(notes),
      guestUids: guestUids.toList()..sort(),
      expenseId: initial?.expenseId,
    );
  }

  void dispose() {
    for (final controller in [
      name, address, city, country, bookedViaOther, bookingUrl,
      propertyUrl, confirmationCode, notes,
    ]) {
      controller.dispose();
    }
  }
}
