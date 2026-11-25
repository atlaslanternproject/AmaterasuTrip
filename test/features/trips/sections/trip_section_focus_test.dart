// Test del risalto dopo "Cerca" (nuova tappa 2b) nell'elenco comune delle
// sezioni, provato sulla pagina Note: l'elemento segnato viene raggiunto
// anche se è in fondo, ha il bordo per qualche secondo e poi lo perde; se
// non è nell'elenco (filtri) compare l'avviso; il segno si usa una volta.

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/notes/models/trip_note.dart';
import 'package:amaterasutrip/features/trips/notes/providers/trip_notes_provider.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/notes/trip_notes_page.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_focus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_section_store.dart';

class _Preset extends TripSectionFocus {
  _Preset(this.id);

  final String id;

  @override
  String? build() => id;
}

final _notes = [
  for (var i = 0; i < 40; i++)
    TripNote(id: 'n$i', tripId: 't1', createdByUid: 'anna', title: 'Nota $i'),
];

final _border = find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).border ==
          Border.all(color: AmaterasuColors.primary, width: 2),
);

Future<void> open(WidgetTester tester, String focus) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1000, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    sectionsTestApp(
      const TripNotesPage(tripId: 't1'),
      overrides: [
        tripNotesStoreProvider.overrideWithValue(
          FakeSectionStore<TripNote>(items: _notes),
        ),
        tripSectionFocusProvider.overrideWith(() => _Preset(focus)),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the searched item is reached and highlighted', (tester) async {
    await open(tester, 'n35');
    expect(_border, findsOneWidget);
    expect(find.text('Nota 35').hitTestable(), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.text('Nota 35')),
    );
    expect(container.read(tripSectionFocusProvider), isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(_border, findsNothing);
  });

  testWidgets('an item hidden by the filters: notice', (tester) async {
    await open(tester, 'missing');
    expect(find.textContaining('nascosto dai filtri'), findsOneWidget);
    expect(_border, findsNothing);
  });
}
