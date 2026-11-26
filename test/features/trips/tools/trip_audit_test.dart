// Test dell'Audit Trail (v1.58.0): voci con username, "Utente eliminato"
// (membro senza profilo) ed "Ex viaggiatore" (non più membro), campi con
// prima → dopo, pagine da 30 con "Mostra altre", filtri passati alla
// lettura, elenco vuoto, rimando alle spese, 130 % su telefono.

import 'package:amaterasutrip/features/trips/tools/audit/trip_audit_data.dart';
import 'package:amaterasutrip/features/trips/tools/audit/trip_audit_names.dart';
import 'package:amaterasutrip/features/trips/tools/audit/trip_audit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../budget/support/fake_budget_api.dart';
import '../sections/support/fake_section_store.dart';

TripAuditEntry entry(
  int i, {
  String? actor = 'anna',
  String action = 'update',
}) => TripAuditEntry(
  id: 'e$i',
  section: i.isEven ? 'transports' : 'shoppingItems',
  itemId: 'item$i',
  itemName: 'Voce $i',
  action: action,
  actorUid: actor,
  at: DateTime(2027, 4, 10, 9, 5),
  changes: i == 0
      ? const [(field: 'number', before: 'AZ1', after: 'AZ2')]
      : const [],
);

class FakeAudit implements TripAuditSource {
  FakeAudit(this.all);

  final List<TripAuditEntry> all;
  final asked = <TripAuditFilters>[];

  @override
  Future<TripAuditChunk> page(
    String tripId,
    TripAuditFilters filters, {
    Object? after,
    DateTime? now,
  }) async {
    asked.add(filters);
    final start = after as int? ?? 0;
    final list = all
        .where((e) => filters.section == null || e.section == filters.section)
        .toList();
    final end = (start + 30).clamp(0, list.length);
    return (
      entries: list.sublist(start, end),
      next: end < list.length ? end : null,
    );
  }
}

Future<FakeAudit> open(
  WidgetTester tester,
  List<TripAuditEntry> all, {
  double width = 1000,
}) async {
  SharedPreferences.setMockInitialValues({});
  bigWindow(tester, width: width);
  final source = FakeAudit(all);
  await tester.pumpWidget(
    sectionsTestApp(
      const TripAuditPage(tripId: 't1'),
      overrides: [
        tripAuditSourceProvider.overrideWithValue(source),
        tripAuditMembersProvider(
          't1',
        ).overrideWith((ref) => const {'anna': 'Anna', 'gone': null}),
      ],
      budget: FakeBudgetApi(
        uid: 'anna',
        members: const [
          {'uid': 'anna', 'name': 'Anna'},
        ],
        historyResponse: const {
          'events': [
            {'type': 'created', 'expenseId': 'e1', 'actorUid': 'anna'},
          ],
          'expenses': {
            'e1': {'title': 'Cena sushi'},
          },
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return source;
}

void main() {
  testWidgets('names and changes; no separate expenses link', (tester) async {
    await open(tester, [
      entry(0),
      entry(1, actor: 'gone', action: 'create'),
      entry(2, actor: 'left', action: 'delete'),
    ]);
    expect(find.text('Anna ha modificato «Voce 0»'), findsOneWidget);
    expect(find.text('Utente eliminato ha creato «Voce 1»'), findsOneWidget);
    expect(find.text('Ex viaggiatore ha eliminato «Voce 2»'), findsOneWidget);
    expect(find.text('number: AZ1 → AZ2'), findsOneWidget);
    expect(find.textContaining('Trasporti'), findsWidgets);
    expect(find.byKey(const Key('audit-expenses')), findsNothing);
  });

  testWidgets('"Spese" filter shows the budget history, no register read', (
    tester,
  ) async {
    final source = await open(tester, [entry(0)]);
    await tapKey(tester, 'audit-filters');
    await tapKey(tester, 'audit-filter-person-anna');
    await tapKey(tester, 'audit-filter-section-expenses');
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('audit-expenses')), findsOneWidget);
    expect(find.byKey(const Key('audit-expenses-filters')), findsOneWidget);
    expect(find.textContaining('Cena sushi'), findsOneWidget);
    expect(find.text('Anna ha modificato «Voce 0»'), findsNothing);
    // Only the first register page (opening, person filter): none for Spese.
    expect(source.asked.where((f) => f.section == 'expenses'), isEmpty);
  });

  testWidgets('pages of 30 and filters passed to the reading', (tester) async {
    final source = await open(tester, [for (var i = 0; i < 35; i++) entry(i)]);
    expect(source.asked, hasLength(1));
    final list = find.descendant(
      of: find.byKey(const Key('audit-page')),
      matching: find.byType(Scrollable),
    );
    final more = find.byKey(const Key('audit-more'));
    await tester.scrollUntilVisible(more, 600, scrollable: list);
    await tester.drag(list, const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.tap(more);
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    // Second page asked once, then nothing more to load.
    expect(source.asked, hasLength(2));
    expect(find.byKey(const Key('audit-more')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('audit-filters')),
      -600,
      scrollable: list,
    );
    await tapKey(tester, 'audit-filters');
    await tapKey(tester, 'audit-filter-section-transports');
    expect(source.asked.last.section, 'transports');
  });

  testWidgets('empty register and phone at 130%', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, const [], width: 390);
    expect(find.byKey(const Key('audit-empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
