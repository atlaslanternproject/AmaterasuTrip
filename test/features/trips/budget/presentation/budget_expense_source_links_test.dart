// Test automatici del riquadro "Origine e link" nel dettaglio di una spesa:
// compare solo con sezione di origine o link, con "Vai al trasporto".
// Casi, ad esempio: "shows go to transport and the link", "hidden without data".

import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_source_links.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_budget_api.dart';

void main() {
  testWidgets('shows go to transport and the link', (tester) async {
    await tester.pumpWidget(
      budgetTestApp(
        const BudgetExpenseSourceLinks(
          tripId: 't1',
          expense: {
            'source': {'section': 'transports', 'id': 'x1'},
            'link': 'https://www.ita-airways.com',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Closed like the other boxes of the expense details.
    await tester.tap(find.text('Origine e link'));
    await tester.pumpAndSettle();
    expect(find.text('Vai al trasporto'), findsOneWidget);
    expect(find.text('www.ita-airways.com'), findsOneWidget);
  });

  testWidgets('hidden without source and link', (tester) async {
    await tester.pumpWidget(
      budgetTestApp(
        const BudgetExpenseSourceLinks(tripId: 't1', expense: {'title': 'x'}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Origine e link'), findsNothing);
  });
}
