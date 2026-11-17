// Parte di trip_overview_page.dart: copertina di riserva,
// sole decorativo e bottoni dell'intestazione.

part of 'trip_overview_page.dart';

// TODO(audit): C10 copertina di riserva simile in 3 file: unificare solo se l'aspetto resta identico.
class _TripCoverFallback extends StatelessWidget {
  const _TripCoverFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF35160F), Color(0xFF1C100D), Color(0xFF0D0908)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: 68, right: -34, child: _FallbackSun()),
          Positioned(
            left: -40,
            bottom: 40,
            child: Icon(
              Icons.landscape_outlined,
              size: 190,
              color: Color(0x1AFF8A4C),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackSun extends StatelessWidget {
  const _FallbackSun();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 190,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0x99FF9A4E), Color(0x44E65B2A), Color(0x00E65B2A)],
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x990A0807),
      shape: const CircleBorder(side: BorderSide(color: Color(0x664B2A20))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AmaterasuColors.textCreamSoft, size: 23),
        ),
      ),
    );
  }
}
