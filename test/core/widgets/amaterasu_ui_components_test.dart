// Test automatici dei componenti delle direttive grafiche: quattro tipi di
// pulsante, "Modifica" a matita (parola su schermo largo), pannello dal
// basso o finestra centrale, doppia conferma e sezione a tendina.
// Casi, ad esempio: "destructive confirm asks twice", "fold section shows the summary when closed".

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_edit_button.dart';
import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_confirm.dart';
import 'package:amaterasutrip/core/widgets/inputs/amaterasu_fold_section.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(
  WidgetTester tester,
  Widget child, {
  double width = 1000,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('four kinds of button', (tester) async {
    await pump(
      tester,
      Column(
        children: [
          AmaterasuButton.primary(label: 'P', onPressed: () {}),
          AmaterasuButton.secondary(label: 'S', onPressed: () {}),
          AmaterasuButton.tertiary(label: 'T', onPressed: () {}),
          AmaterasuButton.destructive(label: 'D', onPressed: () {}),
        ],
      ),
    );
    expect(find.byType(FilledButton), findsNWidgets(2));
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
    final red = tester.widget<FilledButton>(
      find.ancestor(of: find.text('D'), matching: find.byType(FilledButton)),
    );
    expect(red.style!.backgroundColor!.resolve({}), AmaterasuColors.error);
  });

  testWidgets('edit pencil: word on wide screens, icon on phones', (
    tester,
  ) async {
    await pump(tester, AmaterasuEditButton(onPressed: () {}));
    expect(find.text('Modifica'), findsOneWidget);
    await pump(tester, AmaterasuEditButton(onPressed: () {}), width: 380);
    expect(find.text('Modifica'), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  for (final width in [1000.0, 380.0]) {
    testWidgets('destructive confirm asks twice (width $width)', (
      tester,
    ) async {
      bool? result;
      await pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await confirmAmaterasuAction(
              context,
              title: 'Eliminare?',
              body: 'Vale per tutti.',
              confirmLabel: 'Elimina',
              destructive: true,
            ),
            child: const Text('open'),
          ),
        ),
        width: width,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(width < 600 ? BottomSheet : Dialog), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-ok')));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.text('Sì, conferma'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-ok')));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });
  }

  testWidgets('cancel returns false', (tester) async {
    bool? result;
    await pump(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await confirmAmaterasuAction(
            context,
            title: 'Salvare?',
            body: '…',
            confirmLabel: 'Salva',
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-cancel')));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('fold section shows the summary when closed', (tester) async {
    await pump(
      tester,
      const AmaterasuFoldSection(
        title: 'Date',
        icon: Icons.event,
        summary: '13 ago → 14 ago',
        initiallyOpen: false,
        children: [Text('campo')],
      ),
    );
    expect(find.text('campo'), findsNothing);
    expect(find.text('13 ago → 14 ago'), findsOneWidget);
    await tester.tap(find.text('Date'));
    await tester.pumpAndSettle();
    expect(find.text('campo'), findsOneWidget);
    expect(find.text('13 ago → 14 ago'), findsNothing);
    await pump(
      tester,
      const AmaterasuFoldSection(
        title: 'Errore',
        icon: Icons.event,
        initiallyOpen: false,
        forceOpen: true,
        children: [Text('campo')],
      ),
    );
    expect(find.text('campo'), findsOneWidget);
  });
}
