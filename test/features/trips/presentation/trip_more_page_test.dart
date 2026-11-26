// Test della pagina "Altro": la barra "Cerca" in alto apre la ricerca di
// sempre, "Cerca" non è più una voce dell'elenco e "Viaggiatori" (pagina
// segnaposto) non c'è più; nessun errore di spazio al 130 % su telefono.

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/trip_more_page.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<void> open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/trips/t1/more',
    routes: [
      GoRoute(
        path: '/trips/:tripId/more',
        builder: (_, s) => TripMorePage(tripId: s.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/trips/:tripId/more/:page',
        builder: (_, s) => Text('page ${s.pathParameters['page']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
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
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('search bar on top, no Travelers and no Search item', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Viaggiatori'), findsNothing);
    expect(find.text('Cerca'), findsNothing);
    await tester.tap(find.byKey(const Key('more-search')));
    await tester.pumpAndSettle();
    expect(find.text('page search'), findsOneWidget);
  });
}
