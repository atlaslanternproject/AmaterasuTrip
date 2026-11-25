// Indicatore di caricamento dell'app: il sole del caricamento iniziale
// (web/index.html, Extra G) disegnato in Flutter con i colori del tema:
// nucleo oro → rosso che pulsa e anello di raggi che gira. Si adatta allo
// spazio (anche dentro un pulsante); fermo con "riduci animazioni".

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

class AmaterasuLoader extends StatefulWidget {
  const AmaterasuLoader({super.key, this.size = 36});

  /// Largest size; smaller when the space around is smaller.
  final double size;

  @override
  State<AmaterasuLoader> createState() => _AmaterasuLoaderState();
}

class _AmaterasuLoaderState extends State<AmaterasuLoader>
    with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    still ? _turn.stop() : _turn.repeat();
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  // FittedBox (not LayoutBuilder) so it also works where Flutter asks for
  // intrinsic sizes, e.g. inside some dialogs.
  @override
  Widget build(BuildContext context) => Center(
    widthFactor: 1,
    heightFactor: 1,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Semantics(
        label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _turn,
            builder: (_, _) => CustomPaint(painter: _SunPainter(_turn.value)),
          ),
        ),
      ),
    ),
  );
}

class _SunPainter extends CustomPainter {
  const _SunPainter(this.t);

  /// 0..1 along the 9-second turn.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    // Glow pulse every 2.4 s (as in index.html).
    final pulse = 1 + 0.06 * math.sin(t * 9 / 2.4 * 2 * math.pi).abs();
    final core = r * (24 / 42) * pulse;
    canvas.drawCircle(
      c,
      core * 1.25,
      Paint()
        ..color = AmaterasuColors.primary.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.2),
    );
    canvas.drawCircle(
      c,
      core,
      Paint()
        ..shader = const RadialGradient(
          colors: [AmaterasuColors.accentGold, AmaterasuColors.primary],
          stops: [0, 0.7],
        ).createShader(Rect.fromCircle(center: c, radius: core)),
    );
    // Twelve rays on the outer ring, turning.
    final ray = Paint()
      ..color = AmaterasuColors.accentGold.withValues(alpha: 0.85)
      ..strokeWidth = math.max(1.5, r * 0.12)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = (i / 12 + t) * 2 * math.pi;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * r * 0.82, c + dir * r * 0.97, ray);
    }
  }

  @override
  bool shouldRepaint(_SunPainter old) => old.t != t;
}
