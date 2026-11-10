import 'package:amaterasutrip/features/trips/budget/presentation/budget_create_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_budget_api.dart';

/// B8.7: the create dialog opens in both languages and its texts come
/// from the translation files (lib/l10n).
///
/// Known, pre-existing and visual only: Flutter warns in debug mode that a
/// ListTile of this dialog sits on a colored box (ink splash not visible).
/// That warning is tolerated here; any other error fails the test.
const knownWarning = 'ListTile background color or ink splashes';

void main() {
  for (final (locale, title, back) in const [
    ('it', 'Inserisci il nome della spesa.', 'Indietro'),
    ('en', 'Enter an expense name.', 'Back'),
  ]) {
    testWidgets('create dialog renders in "$locale"', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = FakeBudgetApi(
        members: [
          {'uid': 'A', 'name': 'Anna'},
          {'uid': 'B', 'name': 'Bruno'},
        ],
      );
      final unexpected = <FlutterErrorDetails>[];
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.exceptionAsString().contains(knownWarning)) {
          unexpected.add(details);
        }
      };
      await tester.pumpWidget(
        budgetTestApp(
          BudgetCreateDialog(api: api, currency: 'EUR'),
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BudgetCreateDialog), findsOneWidget);

      // Going on without a name shows the translated error.
      final next = find.byType(FilledButton).last;
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      FlutterError.onError = original;
      expect(unexpected, isEmpty);
      expect(find.text(title), findsOneWidget);
      expect(find.text(back), findsNothing);
    });
  }
}
