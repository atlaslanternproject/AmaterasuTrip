// Supporto ai test delle sezioni del viaggio: archivio finto in memoria
// (registra creazioni, modifiche, spese collegate ed eliminazioni) e app di
// prova con i provider del viaggio sostituiti.

import 'dart:async';

import 'package:amaterasutrip/core/places/amaterasu_place_providers.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_section_categories_store.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_section_store.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../budget/support/fake_budget_api.dart' show FakeBudgetApi;
import '../../stays/support/fake_places.dart';
import '../../stays/support/fake_trip_stays.dart' show FakePlaceInfo;

class FakeSectionStore<T extends TripSectionItem>
    implements TripSectionStore<T> {
  FakeSectionStore({this.uid = 'anna', List<T> items = const []})
    : _items = List.of(items);

  final String? uid;
  final List<T> _items;
  final created = <T>[];
  final updated = <T>[];
  final deleted = <T>[];
  final links = <(String, String)>[];
  bool failSave = false;
  final _controller = StreamController<List<T>>.broadcast();

  @override
  String? get currentUid => uid;

  @override
  Stream<List<T>> watch(String tripId) async* {
    yield List.of(_items);
    yield* _controller.stream;
  }

  @override
  Future<String> create(T item) async {
    if (failSave) throw StateError('offline');
    created.add(item);
    return 'new-${created.length}';
  }

  @override
  Future<void> update(T item) async {
    if (failSave) throw StateError('offline');
    updated.add(item);
  }

  @override
  Future<void> linkExpense(T item, String expenseId) async =>
      links.add((item.id, expenseId));

  @override
  Future<void> delete(T item) async {
    deleted.add(item);
    _items.removeWhere((i) => i.id == item.id);
    _controller.add(List.of(_items));
  }
}

/// App with the trip providers replaced: owner 'anna', travelers Anna and
/// Bruno, budget in EUR, Google search with FakePlaces.
Widget sectionsTestApp(
  Widget child, {
  required List<Override> overrides,
  String ownerUid = 'anna',
  String locale = 'it',
  FakeBudgetApi? budget,
  FakePlaceInfo? placeInfo,
  FakeCategoriesStore? categories,
}) => ProviderScope(
  overrides: [
    tripStaysOwnerUidProvider('t1').overrideWith((ref) => ownerUid),
    tripStaysMemberNamesProvider(
      't1',
    ).overrideWith((ref) => const {'anna': 'Anna', 'bruno': 'Bruno'}),
    tripStaysBudgetApiProvider('t1').overrideWith(
      (ref) =>
          budget ??
          FakeBudgetApi(
            uid: 'anna',
            members: [
              {'uid': 'anna', 'name': 'Anna'},
              {'uid': 'bruno', 'name': 'Bruno'},
            ],
          ),
    ),
    tripStaysTripInfoProvider('t1').overrideWith(
      (ref) => (
        currency: 'EUR',
        start: DateTime(2027, 4, 10),
        end: DateTime(2027, 4, 20),
      ),
    ),
    amaterasuPlaceSearchProvider.overrideWithValue(FakePlaces()),
    amaterasuPlaceInfoProvider.overrideWithValue(placeInfo ?? FakePlaceInfo()),
    tripSectionCategoriesStoreProvider.overrideWithValue(
      categories ?? FakeCategoriesStore(const ['Da non perdere']),
    ),
    ...overrides,
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

/// Large window so that every card and editor field can be reached.
void bigWindow(WidgetTester tester, {double width = 1000}) {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

/// Opens the filters sheet of [prefix], picks [key] and closes the sheet.
Future<void> pickFilter(WidgetTester tester, String prefix, String key) async {
  await tapKey(tester, '$prefix-filters');
  await tapKey(tester, key);
  await tapKey(tester, '$prefix-sheet-done');
}

/// Trip categories kept in memory instead of Firestore.
class FakeCategoriesStore implements TripSectionCategoriesStore {
  FakeCategoriesStore([List<String> initial = const []]) : saved = [...initial];

  final List<String> saved;

  @override
  Future<List<String>> labels(String tripId) async => List.of(saved);

  @override
  Future<void> add(String tripId, String label) async {
    if (!saved.contains(label)) saved.add(label);
  }
}
