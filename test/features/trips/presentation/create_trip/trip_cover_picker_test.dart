import 'dart:convert';
import 'dart:typed_data';

import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/widgets/trip_cover_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  const onePixelPng =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
      'YAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

  testWidgets('shows fallback when no local cover is selected', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripCoverPicker(changePhotoLabel: 'Cambia foto', onTap: () {}),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.text('Cambia foto'), findsOneWidget);
    expect(find.byIcon(Icons.temple_buddhist_rounded), findsOneWidget);
    expect(find.byIcon(Icons.landscape_rounded), findsOneWidget);
  });

  testWidgets('renders an XFile preview without using a filesystem path', (
    tester,
  ) async {
    final bytes = Uint8List.fromList(base64Decode(onePixelPng));

    final image = XFile.fromData(
      bytes,
      name: 'cover.png',
      mimeType: 'image/png',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripCoverPicker(
            changePhotoLabel: 'Cambia foto',
            localImage: image,
            onTap: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('forwards the change photo tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripCoverPicker(
            changePhotoLabel: 'Cambia foto',
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Cambia foto'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
