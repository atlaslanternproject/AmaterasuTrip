part of 'trip_overview_page.dart';

class _NoOverscrollBehavior extends ScrollBehavior {
  const _NoOverscrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _TripStatusChip extends StatelessWidget {
  const _TripStatusChip({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final start = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );

    final String label;
    final IconData icon;

    // Status volutamente invariati per ora.
    if (trip.status == TripStatus.closed) {
      label = l10n.tripsCompleted;
      icon = Icons.check_circle_outline_rounded;
    } else if (today.isBefore(start)) {
      label = l10n.tripsUpcoming;
      icon = Icons.schedule_rounded;
    } else {
      label = l10n.tripsInProgress;
      icon = Icons.local_fire_department_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC32150F),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xAAFF7A3D)),
        boxShadow: const [BoxShadow(color: Color(0x33FF6B32), blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFFFA05E)),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFFFC28F),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewActionCard extends StatelessWidget {
  const _OverviewActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  static const Color _surfaceColor = Color(0xFF1A1411);
  static const Color _borderColor = Color(0xFF4B2A20);
  static const Color _accentColor = AmaterasuColors.accentOrangeBright;
  static const Color _titleColor = AmaterasuColors.textCreamSoft;
  static const Color _secondaryTextColor = Color(0xFFB9AA9B);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(AmaterasuSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF281711),
                  borderRadius: BorderRadius.circular(AmaterasuRadius.md),
                  border: Border.all(color: const Color(0xFF5A2B1D)),
                ),
                child: Icon(icon, color: _accentColor, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AmaterasuSpacing.xs),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AmaterasuSpacing.sm),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB96A42)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripOverviewMessage extends StatelessWidget {
  const _TripOverviewMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AmaterasuSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AmaterasuColors.accentBudget),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AmaterasuColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
