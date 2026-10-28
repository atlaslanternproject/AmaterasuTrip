import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class E2eeQrScannerPage extends StatefulWidget {
  const E2eeQrScannerPage({super.key});

  @override
  State<E2eeQrScannerPage> createState() => _E2eeQrScannerPageState();
}

class _E2eeQrScannerPageState extends State<E2eeQrScannerPage> {
  late final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (!mounted || _handled) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value == null || value.length > 1500) {
        continue;
      }

      if (!value.startsWith('amaterasu-enroll-v1:') &&
          !value.startsWith('amaterasu-approval-v1:') &&
          !value.startsWith('amaterasu-profile-request-v1:') &&
          !value.startsWith('amaterasu-profile-grant-v1:')) {
        continue;
      }

      _handled = true;
      Navigator.of(context).pop(value);
      return;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF100C0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF100C0A),
        title: Text(l10n.accountE2eeQrScanTitle),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.accountE2eeQrCameraError,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const IgnorePointer(
            child: CustomPaint(painter: _AmaterasuScanFrame()),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 35),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6100C0A)],
                  ),
                ),
                child: Text(
                  l10n.accountE2eeQrHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF2E7D5),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmaterasuScanFrame extends CustomPainter {
  const _AmaterasuScanFrame();

  @override
  void paint(Canvas canvas, Size size) {
    final side = (size.width - 60).clamp(190.0, 350.0).toDouble();

    final center = Offset(size.width / 2, size.height * 0.44);

    final rect = Rect.fromCenter(center: center, width: side, height: side);

    final hole = RRect.fromRectAndRadius(rect, const Radius.circular(20));

    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(hole);

    canvas.drawPath(mask, Paint()..color = const Color(0xB8100C0A));

    final guide = Paint()
      ..color = const Color(0xFFF0A54C)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const length = 30.0;

    final left = rect.left;
    final right = rect.right;
    final top = rect.top;
    final bottom = rect.bottom;

    canvas.drawLine(Offset(left, top + length), Offset(left, top + 16), guide);

    canvas.drawLine(
      Offset(left, top + 16),
      Offset(left + length, top + 16),
      guide,
    );

    canvas.drawLine(
      Offset(right - length, top + 16),
      Offset(right, top + 16),
      guide,
    );

    canvas.drawLine(
      Offset(right, top + 16),
      Offset(right, top + length),
      guide,
    );

    canvas.drawLine(
      Offset(left, bottom - length),
      Offset(left, bottom - 16),
      guide,
    );

    canvas.drawLine(
      Offset(left, bottom - 16),
      Offset(left + length, bottom - 16),
      guide,
    );

    canvas.drawLine(
      Offset(right - length, bottom - 16),
      Offset(right, bottom - 16),
      guide,
    );

    canvas.drawLine(
      Offset(right, bottom - 16),
      Offset(right, bottom - length),
      guide,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
