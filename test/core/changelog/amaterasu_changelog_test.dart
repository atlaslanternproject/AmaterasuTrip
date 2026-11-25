// Test automatici delle novità per versione (Extra A): il file
// assets/changelog/changelog.json ha la voce della versione di pubspec
// (it/en), "Cosa c'è di nuovo" compare una volta sola dopo un
// aggiornamento e mai alla prima installazione, elenco di tutte le versioni.
// Casi, ad esempio: "the pubspec version has its news", "shown once after an update".

import 'dart:io';

import 'package:amaterasutrip/core/changelog/amaterasu_changelog.dart';
import 'package:amaterasutrip/core/changelog/amaterasu_whats_new.dart';
import 'package:amaterasutrip/core/changelog/amaterasu_whats_new_gate.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final file = AmaterasuChangelog.parse(
  File('assets/changelog/changelog.json').readAsStringSync(),
);

Widget app(Widget child) => MaterialApp(
  locale: const Locale('it'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

void main() {
  test('the pubspec version has its news in Italian and English', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([0-9.]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1)!;
    final entry = file.where((e) => e.version == version);
    expect(entry, isNotEmpty, reason: 'Add $version to changelog.json');
    expect(entry.single.linesFor('it'), isNotEmpty);
    expect(entry.single.news['en'], isNotEmpty);
    // Newest first, no duplicates.
    expect(file.map((e) => e.version).toSet().length, file.length);
  });

  test('shown once after an update, never on the first run', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await AmaterasuWhatsNew.pending('1.35.1', file), isNull);
    expect(await AmaterasuWhatsNew.pending('1.35.1', file), isNull);
    final news = await AmaterasuWhatsNew.pending('1.36.0', file);
    expect(news?.version, '1.36.0');
    expect(await AmaterasuWhatsNew.pending('1.36.0', file), isNull);
  });

  testWidgets('the gate shows the news of the new version', (tester) async {
    SharedPreferences.setMockInitialValues({
      AmaterasuWhatsNew.seenKey: '1.35.1',
    });
    resetAmaterasuWhatsNewGate();
    await tester.pumpWidget(
      app(
        AmaterasuWhatsNewGate(
          version: () async => '1.36.0',
          child: const Text('home'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Novità della versione 1.36.0'), findsOneWidget);
    await tester.tap(find.byKey(const Key('whats-new-ok')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('whats-new')), findsNothing);
  });

  testWidgets('every version in a fold, newest open', (tester) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => AmaterasuWhatsNew.showAll(context),
            child: const Text('versione'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('versione'));
    // The file is read from the app assets (real async work).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tutte le versioni'), findsOneWidget);
    expect(find.byKey(Key('version-${file.first.version}')), findsOneWidget);
  });
}
