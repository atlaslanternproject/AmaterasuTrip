part of 'trip_overview_page.dart';

class _TripHero extends StatelessWidget {
  const _TripHero({required this.trip, required this.onSettingsPressed});

  final Trip trip;
  final VoidCallback onSettingsPressed;

  static const Color _accentColor = AmaterasuColors.accentOrangeBright;
  static const Color _titleColor = Color(0xFFFFF4E7);
  static const Color _secondaryTextColor = Color(0xFFE0CDBA);

  @override
  Widget build(BuildContext context) {
    final coverUrl = trip.coverUrl?.trim();
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;
    final topSafePadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 410,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasCover)
            Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const _TripCoverFallback();
              },
            )
          else
            const _TripCoverFallback(),

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.32, 0.68, 1.0],
                colors: [
                  Color(0x66000000),
                  Color(0x22000000),
                  Color(0x99100C0A),
                  AmaterasuColors.surfaceDeep,
                ],
              ),
            ),
          ),

          Positioned(
            top: topSafePadding + 12,
            left: 16,
            child: _HeroButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () {
                context.go('/trips');
              },
            ),
          ),

          // Solo Impostazioni.
          // Il menu "..." viene rimosso finché non avrà azioni reali.
          Positioned(
            top: topSafePadding + 12,
            right: 16,
            child: _HeroButton(
              icon: Icons.settings_outlined,
              onPressed: onSettingsPressed,
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TripStatusChip(trip: trip),
                const SizedBox(height: 12),
                Text(
                  trip.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _titleColor,
                    fontFamily: 'serif',
                    fontSize: 38,
                    height: 1.02,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
                    shadows: [Shadow(color: Color(0xAA000000), blurRadius: 14)],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: _accentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        trip.destination,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: _accentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _formatDateRange(trip.startDate, trip.endDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateRange(DateTime startDate, DateTime endDate) {
    return '${_formatDate(startDate)} — ${_formatDate(endDate)}';
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}
