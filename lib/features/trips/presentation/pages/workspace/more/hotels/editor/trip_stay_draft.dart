// Stato modificabile dell'editor di un soggiorno: campi di testo, date,
// orari, stato, tipo, contatti, piattaforma, luogo Google, ospiti, costo
// previsto, cancellazione gratuita e servizi. Si crea da un soggiorno
// esistente (o vuoto) e si trasforma in TripStay per salvarlo.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/budget/presentation/budget_money_input.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_amenity.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_booking_platform.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_type.dart';

class TripStayDraft {
  TripStayDraft({
    TripStay? initial,
    required DateTime today,
    String defaultCurrency = 'EUR',
  }) : _initial = initial,
       costCurrency = initial?.estimatedCostCurrency ?? defaultCurrency,
       cost = TextEditingController(text: _costText(initial)),
       directions = TextEditingController(text: initial?.directions ?? ''),
       freeCancellationUntil = initial?.freeCancellationUntil,
       amenities = {...?initial?.amenities},
       name = TextEditingController(text: initial?.name ?? ''),
       address = TextEditingController(text: initial?.address ?? ''),
       city = TextEditingController(text: initial?.city ?? ''),
       country = TextEditingController(text: initial?.country ?? ''),
       bookedViaOther = TextEditingController(
         text: initial?.bookedViaOther ?? '',
       ),
       bookingUrl = TextEditingController(text: initial?.bookingUrl ?? ''),
       propertyUrl = TextEditingController(text: initial?.propertyUrl ?? ''),
       phone = TextEditingController(text: initial?.phone ?? ''),
       email = TextEditingController(text: initial?.email ?? ''),
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
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController confirmationCode;
  final TextEditingController notes;
  final TextEditingController cost;
  final TextEditingController directions;

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
  String costCurrency;
  DateTime? freeCancellationUntil;
  final Set<TripStayAmenity> amenities;

  static String _costText(TripStay? stay) {
    final minor = stay?.estimatedCostMinorUnits;
    final currency = stay?.estimatedCostCurrency;
    if (minor == null || currency == null) return '';
    try {
      return BudgetMoneyInput.plainText(minor, currency);
    } catch (_) {
      return '';
    }
  }

  /// Minor units of the written cost; -1 when the text is not an amount
  /// (the validator then reports it), null when empty.
  int? get _costMinorUnits {
    final text = cost.text.trim();
    if (text.isEmpty) return null;
    try {
      return BudgetMoneyInput.parse(text, costCurrency);
    } catch (_) {
      return -1;
    }
  }

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
      phone: text(phone),
      email: text(email),
      confirmationCode: text(confirmationCode),
      notes: text(notes),
      guestUids: guestUids.toList()..sort(),
      expenseId: initial?.expenseId,
      estimatedCostMinorUnits: _costMinorUnits,
      estimatedCostCurrency: _costMinorUnits == null ? null : costCurrency,
      freeCancellationUntil: freeCancellationUntil,
      amenities: [
        for (final a in TripStayAmenity.values)
          if (amenities.contains(a)) a,
      ],
      directions: text(directions),
    );
  }

  void dispose() {
    for (final controller in [
      name,
      address,
      city,
      country,
      bookedViaOther,
      bookingUrl,
      propertyUrl,
      phone,
      email,
      confirmationCode,
      notes,
      cost,
      directions,
    ]) {
      controller.dispose();
    }
  }
}
