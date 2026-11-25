// Icone dei pin della Mappa disegnate in Dart (nessuna foto): cerchio del
// colore di accento con l'icona della sezione, oppure con il numero dei
// luoghi di un gruppo. Una cache per icona evita di ridisegnarle.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

abstract final class TripMapMarkers {
  static const _size = 96.0;
  static final _cache = <String, BitmapDescriptor>{};

  static Future<BitmapDescriptor> icon(IconData icon) => _draw(
    'i${icon.codePoint}',
    String.fromCharCode(icon.codePoint),
    icon.fontFamily,
    icon.fontPackage,
  );

  static Future<BitmapDescriptor> count(int n) =>
      _draw('c$n', '$n', null, null);

  static Future<BitmapDescriptor> _draw(
    String key,
    String text,
    String? fontFamily,
    String? fontPackage,
  ) async {
    final cached = _cache[key];
    if (cached != null) return cached;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(_size / 2, _size / 2);
    canvas.drawCircle(
      center,
      _size / 2,
      Paint()..color = AmaterasuColors.surfaceDeep,
    );
    canvas.drawCircle(
      center,
      _size / 2 - 6,
      Paint()..color = AmaterasuColors.accentBudget,
    );
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontFamily == null ? 40 : 50,
          fontFamily: fontFamily,
          package: fontPackage,
          fontWeight: FontWeight.w700,
          color: AmaterasuColors.textPrimary,
        ),
      ),
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
    final image = await recorder.endRecording().toImage(
      _size.toInt(),
      _size.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 36,
      height: 36,
    );
    return _cache[key] = descriptor;
  }
}
