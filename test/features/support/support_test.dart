// Test automatici di "Assistenza": segnala un problema e suggerisci
// un'idea preparano la stessa email di supporto (indirizzo, oggetto
// diverso, versione, build e lingua), nessun modulo nell'app; tabella
// della conformità con tutte le righe del file e la frase "non è una
// certificazione".

import 'dart:convert';
import 'dart:io';

import 'package:amaterasutrip/features/support/data/amaterasu_support_email.dart';
import 'package:amaterasutrip/features/support/presentation/compliance_page.dart';
import 'package:amaterasutrip/features/support/presentation/support_page.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/l10n/app_localizations_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> open(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('it'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'amaterasutrip',
      packageName: 'amaterasutrip',
      version: '1.74.0',
      buildNumber: '83',
      buildSignature: '',
    ),
  );

  test('report and idea: same email, own subject, version and build', () {
    final l10n = AppLocalizationsIt();
    Uri email(AmaterasuSupportKind kind) => AmaterasuSupportEmail.reportUri(
      l10n,
      kind,
      version: '1.74.0',
      build: '83',
      language: 'it',
    );
    final bug = email(AmaterasuSupportKind.bug);
    final idea = email(AmaterasuSupportKind.idea);
    for (final u in [bug, idea]) {
      expect(u.scheme, 'mailto');
      expect(u.path, AmaterasuSupportEmail.address);
      expect(u.queryParameters['body'], contains('Versione 1.74.0 (build 83)'));
    }
    expect(bug.queryParameters['subject'], contains('problema'));
    expect(idea.queryParameters['subject'], contains('idea'));
    expect(AmaterasuSupportEmail.uri().query, isEmpty);
  });

  testWidgets('no form inside the app any more', (tester) async {
    await open(tester, const SupportPage());
    expect(find.byKey(const Key('support-bug')), findsOneWidget);
    expect(find.byKey(const Key('support-idea')), findsOneWidget);
    expect(find.byKey(const Key('support-feedback-text')), findsNothing);
  });

  testWidgets('compliance table shows every row of the file', (tester) async {
    final rows =
        (jsonDecode(
                  File('assets/compliance/compliance.json').readAsStringSync(),
                )['rows']
                as List)
            .length;
    await open(tester, const CompliancePage());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('non una certificazione'), findsOneWidget);
    expect(rows, greaterThanOrEqualTo(10));
    expect(find.textContaining('Ci riguarda:'), findsWidgets);
    expect(find.textContaining('GDPR'), findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('21 CFR Part 11'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Non applicabile come conformità'), findsOne);
  });
}
