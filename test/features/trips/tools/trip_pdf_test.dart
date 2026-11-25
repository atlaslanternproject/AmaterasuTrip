// Test del PDF del viaggio (tappa 3c): riepilogo HTML con testi protetti,
// tabelle in ordine di data, annullati esclusi, link della cartella del
// viaggio e degli album (solo http/https); pagina Esporta che apre la
// stampa e avvisa se il browser la blocca; 130 % su telefono.

import 'package:amaterasutrip/features/trips/data/models/trip_cloud_archive.dart';
import 'package:amaterasutrip/features/trips/memories/models/trip_memory.dart';
import 'package:amaterasutrip/features/trips/models/trip.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/tools/export/trip_export_data.dart';
import 'package:amaterasutrip/features/trips/tools/export/trip_export_page.dart';
import 'package:amaterasutrip/features/trips/tools/export/trip_pdf_summary.dart';
import 'package:amaterasutrip/l10n/app_localizations_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';
import '../stays/support/fake_trip_stays.dart' show testStay;

final data = TripExportData(
  stays: [
    testStay('s2', name: 'Ryokan', day: 15),
    testStay('s1', name: 'Hotel <Kyoto>', day: 11),
    testStay('s3', name: 'Annullato', status: TripStayStatus.cancelled),
  ],
  memories: const [
    TripMemory(
      tripId: 't1',
      createdByUid: 'anna',
      kind: TripMemoryKind.album,
      title: 'Foto Kyoto',
      url: 'https://photos.app.goo.gl/abc',
    ),
    TripMemory(
      tripId: 't1',
      createdByUid: 'anna',
      kind: TripMemoryKind.album,
      title: 'Strano',
      url: 'javascript:alert(1)',
    ),
  ],
);

final trip = Trip(
  id: 't1',
  name: 'Giappone & Corea',
  destination: 'Tokyo',
  startDate: DateTime(2027, 4, 10),
  endDate: DateTime(2027, 4, 20),
  currency: 'EUR',
  ownerUid: 'anna',
  status: TripStatus.active,
  createdAt: null,
  updatedAt: null,
  cloudArchive: const TripCloudArchive(
    provider: TripCloudProvider.googleDrive,
    folderId: 'f1',
    folderName: 'Giappone',
    folderUrl: 'https://drive.google.com/drive/folders/f1',
  ),
);

String day(DateTime d) => '${d.day}/${d.month}';

void main() {
  test('summary: escaped, by date, cancelled out, safe links', () {
    final html = TripPdfSummary.html(
      trip: TripPdfTrip(
        name: 'Giappone & Corea',
        destination: 'Tokyo',
        start: _start,
        end: _end,
        folderUrl: 'https://drive.google.com/drive/folders/f1',
      ),
      data: data,
      l10n: AppLocalizationsIt(),
      dayOf: day,
      timeOf: (t) => t,
      now: DateTime(2027, 4, 1),
    );
    expect(html, contains('<h1>Giappone &amp; Corea</h1>'));
    expect(html, contains('Hotel &lt;Kyoto&gt;'));
    expect(html, isNot(contains('Annullato')));
    expect(
      html.indexOf('Hotel &lt;Kyoto&gt;'),
      lessThan(html.indexOf('Ryokan')),
    );
    expect(html, contains('href="https://drive.google.com/drive/folders/f1"'));
    expect(html, contains('href="https://photos.app.goo.gl/abc"'));
    expect(html, isNot(contains('href="javascript')));
    expect(html, contains('Creato il 1/4 con Amaterasu Trip'));
  });

  testWidgets('page: opens the print page, warns when blocked', (tester) async {
    SharedPreferences.setMockInitialValues({});
    bigWindow(tester);
    final printed = <String>[];
    var allow = true;
    await tester.pumpWidget(
      sectionsTestApp(
        TripExportPage(
          tripId: 't1',
          print: (html) {
            printed.add(html);
            return allow;
          },
        ),
        overrides: [
          tripProvider('t1').overrideWith((ref) => Stream.value(trip)),
          tripExportLoaderProvider.overrideWithValue((id) async => data),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'export-pdf-open');
    expect(printed.single, contains('Giappone &amp; Corea'));
    expect(printed.single, contains('drive.google.com'));
    allow = false;
    await tapKey(tester, 'export-pdf-open');
    expect(find.textContaining('consenti i pop-up'), findsOneWidget);
  });

  testWidgets('phone at 130% without overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    bigWindow(tester, width: 390);
    await tester.pumpWidget(
      sectionsTestApp(
        const TripExportPage(tripId: 't1'),
        overrides: [
          tripProvider('t1').overrideWith((ref) => Stream.value(trip)),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

final _start = DateTime(2027, 4, 10);
final _end = DateTime(2027, 4, 20);
