// Test automatici di "Cerca" (nuova tappa 2a): testo cercabile dai codec
// veri (codice porta, Wi-Fi, telefono, link e identificativi esclusi; voci
// delle checklist incluse), ricerca senza accenti e con più parole,
// ricerche recenti, lettura con gli store delle sezioni (note: solo quelle
// che lo store restituisce), pagina con filtro, pagine da 20, tocco che
// apre la sezione giusta, nessun errore di spazio al 130 %.

import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist_codec.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_focus.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_codec.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_extras.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_page.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_recent.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_text.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../stays/support/fake_trip_stays.dart' show testStay;

TripSearchDoc doc(
  TripSearchSection s,
  String id,
  String title, [
  List<String> texts = const [],
]) => TripSearchDoc(section: s, id: id, title: title, texts: [title, ...texts]);

final docs = [
  doc(TripSearchSection.stays, 's1', 'Hotel Kyoto', ['Città vecchia']),
  doc(TripSearchSection.transports, 't1', 'Volo Roma Tokyo', ['AZ784']),
  doc(TripSearchSection.notes, 'n1', 'Frasi utili', ['Arigatō = grazie']),
  doc(TripSearchSection.checklists, 'c1', 'Valigia', ['Passaporto']),
  for (var i = 0; i < 25; i++)
    doc(TripSearchSection.savedPlaces, 'p$i', 'Tempio $i', ['Kyoto']),
];

Future<void> open(WidgetTester tester, {double width = 1000}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/trips/t1/more/search',
    routes: [
      GoRoute(
        path: '/trips/:tripId/more/search',
        builder: (_, s) => TripSearchPage(tripId: s.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/trips/:tripId/more/:page',
        builder: (_, s) => Text('page ${s.pathParameters['page']}'),
      ),
      GoRoute(
        path: '/trips/:tripId/more/checklists/:listId',
        builder: (_, s) => Text('list ${s.pathParameters['listId']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripSearchLoaderProvider.overrideWithValue((id) async => docs),
        tripSearchUidProvider.overrideWithValue('anna'),
      ],
      child: MaterialApp.router(
        locale: const Locale('it'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('search-field')), text);
  await tester.pumpAndSettle();
}

String? focusOf(WidgetTester tester, String text) => ProviderScope.containerOf(
  tester.element(find.text(text)),
).read(tripSectionFocusProvider);

void main() {
  test('searchable text: user fields only, checklist items included', () {
    final stay = testStay(
      's1',
      phone: '+39 06 123',
      bookingUrl: 'https://b.it',
    );
    // The saved stay with the v2 extras, as the codec writes them.
    final saved = {
      ...TripStayCodec.toMap(stay),
      'extras': const TripStayExtras(
        doorCode: '4321',
        wifiName: 'CasaNet',
        wifiPassword: 'segreta',
        accessNotes: 'Chiavi nella cassetta',
      ).toMap(),
    };
    final texts = tripSearchTexts(saved);
    expect(texts, contains('Hotel Kyoto'));
    expect(texts, contains('Chiavi nella cassetta'));
    for (final hidden in ['4321', 'CasaNet', 'segreta', '+39 06 123', 'anna']) {
      expect(texts.join(' '), isNot(contains(hidden)), reason: hidden);
    }
    expect(texts.where((t) => t.startsWith('http')), isEmpty);

    const list = TripChecklist(
      id: 'c1',
      tripId: 't1',
      createdByUid: 'anna',
      title: 'Valigia',
      entries: {
        'e1': TripChecklistEntry(
          id: 'e1',
          text: 'Passaporto',
          category: 'docs',
          assigneeUid: 'bruno',
        ),
      },
    );
    final listTexts = tripSearchTexts(const TripChecklistCodec().toMap(list));
    expect(listTexts, containsAll(['Valigia', 'Passaporto']));
    expect(listTexts, isNot(contains('bruno')));
  });

  test('match: no case, no accents, every word, short snippet', () {
    expect(
      tripSearchMatch(['Hotel Kyoto', 'Città vecchia'], 'citta'),
      'Città vecchia',
    );
    expect(
      tripSearchMatch(['Volo Roma Tokyo', 'AZ784'], 'az784 roma'),
      'AZ784',
    );
    expect(tripSearchMatch(['Volo Roma'], 'roma parigi'), isNull);
    expect(tripSearchMatch(['x'], '   '), isNull);
    expect(tripSearchSnippet('a' * 200).length, 120);
  });

  test('recent searches: newest first, no repeats, at most 8', () {
    var list = <String>[];
    for (final q in ['kyoto', 'roma', 'Kyoto', ' ', ...List.filled(9, 'x')]) {
      list = TripSearchRecent.add(list, q);
    }
    expect(list, ['x', 'Kyoto', 'roma']);
    expect(
      [
        for (var i = 0; i < 12; i++) '$i',
      ].fold(<String>[], TripSearchRecent.add).length,
      8,
    );
  });

  testWidgets('results, filter by section, pages and open', (tester) async {
    await open(tester);
    expect(find.textContaining('private degli altri'), findsOneWidget);
    await type(tester, 'kyoto');
    // Hotel + 25 places: 26 results, 20 shown, then the others.
    expect(find.text('26 risultati'), findsOneWidget);
    expect(
      find.byKey(const Key('search-result-savedPlaces-p20')),
      findsNothing,
    );
    final list = find.descendant(
      of: find.byKey(const Key('search-results')),
      matching: find.byType(Scrollable),
    );
    final more = find.byKey(const Key('search-more'));
    await tester.scrollUntilVisible(more, 300, scrollable: list);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(more, findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('search-result-savedPlaces-p24')),
      300,
      scrollable: list,
    );
    final stays = find.byKey(const Key('search-section-stays'));
    await tester.scrollUntilVisible(stays, -300, scrollable: list);
    await tester.tap(stays);
    await tester.pumpAndSettle();
    expect(find.text('1 risultato'), findsOneWidget);
    await tester.tap(find.byKey(const Key('search-result-stays-s1')));
    await tester.pumpAndSettle();
    expect(find.text('page hotels'), findsOneWidget);
    // Stays are an approved module: no highlight there.
    expect(focusOf(tester, 'page hotels'), isNull);
  });

  testWidgets('a transport is marked for the highlight', (tester) async {
    await open(tester);
    await type(tester, 'az784');
    await tester.tap(find.byKey(const Key('search-result-transports-t1')));
    await tester.pumpAndSettle();
    expect(find.text('page transport'), findsOneWidget);
    expect(focusOf(tester, 'page transport'), 't1');
  });

  testWidgets('checklist opens its list; recent search is kept', (
    tester,
  ) async {
    await open(tester);
    await type(tester, 'passaporto');
    await tester.tap(find.byKey(const Key('search-result-checklists-c1')));
    await tester.pumpAndSettle();
    expect(find.text('list c1'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(TripSearchRecent.key('anna', 't1')), [
      'passaporto',
    ]);
  });

  testWidgets('no results and recent chip', (tester) async {
    await open(tester);
    await type(tester, 'parigi');
    expect(find.text('Nessun risultato per «parigi».'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.tap(find.byKey(const Key('search-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-recent-parigi')), findsOneWidget);
    await tester.tap(find.byKey(const Key('search-recent-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-recent-parigi')), findsNothing);
  });

  testWidgets('phone at 130% without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, width: 390);
    await type(tester, 'kyoto');
    expect(tester.takeException(), isNull);
  });
}
