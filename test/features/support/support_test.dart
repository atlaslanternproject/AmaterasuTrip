// Test automatici di "Assistenza e privacy" (Extra F): invio di una
// segnalazione o di un'idea (inviata, limite giornaliero, testo vuoto),
// giorno UTC usato dalle regole, tabella della conformità con tutte le
// righe del file e la frase "non è una certificazione".
// Casi, ad esempio: "a report is sent", "daily limit is explained".

import 'dart:convert';
import 'dart:io';

import 'package:amaterasutrip/features/support/data/feedback_repository.dart';
import 'package:amaterasutrip/features/support/presentation/compliance_page.dart';
import 'package:amaterasutrip/features/support/presentation/support_page.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FakeFeedback implements FeedbackRepository {
  FakeFeedback(this.result);

  final FeedbackResult result;
  final sent = <(FeedbackKind, String)>[];

  @override
  Future<FeedbackResult> send(
    FeedbackKind kind,
    String text, {
    required String appVersion,
    required String language,
  }) async {
    sent.add((kind, text));
    return result;
  }
}

Future<void> open(WidgetTester tester, Widget page, FakeFeedback fake) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [feedbackRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(
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
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> write(WidgetTester tester, String text) async {
  await tester.tap(find.byKey(const Key('support-bug')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('support-feedback-text')), text);
  await tester.tap(find.byKey(const Key('support-feedback-send')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'amaterasutrip',
      packageName: 'amaterasutrip',
      version: '1.47.0',
      buildNumber: '52',
      buildSignature: '',
    ),
  );

  test('the id uses the UTC day of the server', () {
    expect(
      FirestoreFeedbackRepository.day(DateTime.utc(2027, 1, 5, 23, 30)),
      '2027-01-05',
    );
  });

  testWidgets('a report is sent', (tester) async {
    final fake = FakeFeedback(FeedbackResult.sent);
    await open(tester, const SupportPage(), fake);
    await write(tester, 'La mappa non si apre');
    expect(fake.sent.single, (FeedbackKind.bug, 'La mappa non si apre'));
    expect(find.text('Grazie! Messaggio inviato.'), findsOneWidget);
  });

  testWidgets('daily limit and empty text are explained', (tester) async {
    final fake = FakeFeedback(FeedbackResult.dailyLimit);
    await open(tester, const SupportPage(), fake);
    await write(tester, '');
    expect(find.text('Scrivi qualcosa prima di inviare.'), findsOneWidget);
    expect(fake.sent, isEmpty);
    await tester.enterText(
      find.byKey(const Key('support-feedback-text')),
      'Idea',
    );
    await tester.tap(find.byKey(const Key('support-feedback-send')));
    await tester.pumpAndSettle();
    expect(find.textContaining('5 messaggi oggi'), findsOneWidget);
  });

  testWidgets('compliance table shows every row of the file', (tester) async {
    final rows =
        (jsonDecode(
                  File('assets/compliance/compliance.json').readAsStringSync(),
                )['rows']
                as List)
            .length;
    await open(
      tester,
      const CompliancePage(),
      FakeFeedback(FeedbackResult.sent),
    );
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
