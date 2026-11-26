// Test dello schema delle Impostazioni (26/11/2026): pagina principale con
// le card in ordine e la stessa distanza; Privacy e legale con Conformità;
// Assistenza con Segnala, Suggerisci e Contatti (niente doppioni di
// versione o privacy); Informazioni con Stato dell'app e Crediti e licenze.

import 'package:amaterasutrip/features/settings/presentation/pages/information/information_page.dart';
import 'package:amaterasutrip/features/settings/presentation/pages/privacy/privacy_page.dart';
import 'package:amaterasutrip/features/settings/presentation/pages/settings_page.dart';
import 'package:amaterasutrip/features/support/presentation/support_page.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> open(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
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
  expect(tester.takeException(), isNull);
}

void main() {
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'amaterasutrip',
      packageName: 'amaterasutrip',
      version: '1.72.0',
      buildNumber: '81',
      buildSignature: '',
    ),
  );

  testWidgets('main page: cards in order, same gap', (tester) async {
    await open(tester, const SettingsPage());
    const order = [
      'account',
      'profile',
      'language',
      'appearance',
      'data',
      'privacy',
      'support',
      'information',
    ];
    final tops = [
      for (final k in order)
        tester.getTopLeft(find.byKey(Key('settings-$k'))).dy,
    ];
    final bottoms = [
      for (final k in order)
        tester.getBottomLeft(find.byKey(Key('settings-$k'))).dy,
    ];
    for (var i = 1; i < order.length; i++) {
      expect(tops[i] - bottoms[i - 1], 10, reason: order[i]);
    }
  });

  testWidgets('Support: report, idea, contacts only', (tester) async {
    await open(tester, const SupportPage());
    for (final k in ['bug', 'idea', 'contacts']) {
      expect(find.byKey(Key('support-$k')), findsOneWidget);
    }
    for (final k in ['status', 'privacy', 'compliance']) {
      expect(find.byKey(Key('support-$k')), findsNothing);
    }
    // Same gap as Privacy and the main page.
    double gap(String a, String b) =>
        tester.getTopLeft(find.byKey(Key('support-$b'))).dy -
        tester.getBottomLeft(find.byKey(Key('support-$a'))).dy;
    expect(gap('bug', 'idea'), 10);
    expect(gap('idea', 'contacts'), 10);
  });

  testWidgets('Privacy and legal has Compliance', (tester) async {
    await open(tester, const PrivacyPage());
    expect(find.text('Privacy e legale'), findsOneWidget);
    expect(find.byKey(const Key('privacy-compliance')), findsOneWidget);
  });

  testWidgets('Information: app status, credits and licenses', (tester) async {
    await open(tester, const InformationPage());
    expect(find.byKey(const Key('information-app')), findsOneWidget);
    await tester.tap(find.byKey(const Key('information-credits')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('information-licenses')), findsOneWidget);
    expect(find.text('Informativa privacy'), findsNothing);
  });
}
