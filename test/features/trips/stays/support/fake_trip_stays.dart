// Supporto ai test di Hotel/Alloggi: repository finto senza Firebase,
// soggiorni di prova e l'app con i provider sostituiti.

import 'package:amaterasutrip/features/trips/stays/data/trip_stays_repository.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:url_launcher/url_launcher.dart';

class FakeTripStaysRepository implements TripStaysRepository {
  FakeTripStaysRepository({this.uid = 'anna'});

  final String? uid;
  final created = <TripStay>[];
  final updated = <TripStay>[];
  final deleted = <String>[];
  final links = <(String, String)>[];
  bool failLink = false;
  bool failSave = false;

  @override
  String? get currentUid => uid;

  @override
  Stream<List<TripStay>> watch(String tripId) => const Stream.empty();

  @override
  Future<String> create(TripStay stay) async {
    if (failSave) throw StateError('offline');
    created.add(stay);
    return 'new-${created.length}';
  }

  @override
  Future<void> update(TripStay stay) async {
    if (failSave) throw StateError('offline');
    updated.add(stay);
  }

  @override
  Future<void> delete({required String tripId, required String stayId}) async =>
      deleted.add(stayId);

  @override
  Future<void> linkExpense({
    required String tripId,
    required String stayId,
    required String expenseId,
  }) async {
    if (failLink) throw StateError('offline');
    links.add((stayId, expenseId));
  }
}

class FakeLaunch {
  final calls = <(Uri, LaunchMode)>[];

  Future<bool> call(Uri uri, {LaunchMode mode = LaunchMode.platformDefault,
      String? webOnlyWindowName}) async {
    calls.add((uri, mode));
    return true;
  }
}

TripStay testStay(
  String id, {
  String name = 'Hotel Kyoto',
  int day = 12,
  int nights = 3,
  TripStayStatus status = TripStayStatus.booked,
  String createdBy = 'anna',
  String? bookingUrl,
  String? propertyUrl,
  String? placeId,
  List<String> guests = const [],
  String? expenseId,
}) => TripStay(
  id: id,
  tripId: 't1',
  name: name,
  checkInDate: DateTime(2027, 4, day),
  checkOutDate: DateTime(2027, 4, day + nights),
  status: status,
  createdByUid: createdBy,
  checkInTime: '15:00',
  city: 'Kyoto',
  country: 'Giappone',
  bookingUrl: bookingUrl,
  propertyUrl: propertyUrl,
  googlePlaceId: placeId,
  guestUids: guests,
  expenseId: expenseId,
);

/// The app with fake stays, owner and member names.
Widget staysTestApp(
  Widget child, {
  required List<TripStay> stays,
  required FakeTripStaysRepository repository,
  String ownerUid = 'anna',
  Map<String, String> names = const {'anna': 'Anna', 'bruno': 'Bruno'},
  List<Override> extra = const [],
  String locale = 'it',
}) => ProviderScope(
  overrides: [
    tripStaysProvider('t1').overrideWith((ref) => Stream.value(stays)),
    tripStaysRepositoryProvider.overrideWithValue(repository),
    tripStaysOwnerUidProvider('t1').overrideWith((ref) => ownerUid),
    tripStaysMemberNamesProvider('t1').overrideWith((ref) => names),
    ...extra,
  ],
  child: MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);
