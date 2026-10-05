import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/features/trips/models/trip.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripOverviewPage extends ConsumerWidget {
  const TripOverviewPage({super.key, required this.tripId});

  final String tripId;

  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _accentColor = Color(0xFFFF7A3D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tripAsync = ref.watch(tripProvider(tripId));

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: tripAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _accentColor)),
        error: (error, stackTrace) => _TripOverviewMessage(
          icon: Icons.error_outline,
          message: l10n.tripOverviewError,
        ),
        data: (trip) {
          if (trip == null) {
            return _TripOverviewMessage(
              icon: Icons.travel_explore_outlined,
              message: l10n.tripOverviewNotFound,
            );
          }

          return _TripOverviewContent(trip: trip);
        },
      ),
    );
  }
}

class _TripOverviewContent extends StatelessWidget {
  const _TripOverviewContent({required this.trip});

  final Trip trip;

  static const Color _titleColor = Color(0xFFF4E9DA);
  static const Color _secondaryTextColor = Color(0xFFB9AA9B);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // HERO FISSA:
        // è intenzionalmente FUORI dalla zona scrollabile.
        _TripHero(
          trip: trip,
          onSettingsPressed: () {
            context.push('/trips/${trip.id}/settings');
          },
        ),

        // SOLO il contenuto sotto la Hero può scorrere.
        Expanded(
          child: ScrollConfiguration(
            behavior: const _NoOverscrollBehavior(),
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Text(
                  l10n.tripOverviewTitle,
                  style: const TextStyle(
                    color: _titleColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.tripOverviewExploreSubtitle,
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                _OverviewActionCard(
                  icon: Icons.route_outlined,
                  title: l10n.tripOverviewItinerary,
                  description: l10n.tripOverviewItinerarySubtitle,
                  onTap: () {
                    context.go('/trips/${trip.id}/itinerary');
                  },
                ),
                const SizedBox(height: 12),
                _OverviewActionCard(
                  icon: Icons.favorite_border_rounded,
                  title: l10n.tripOverviewBucketList,
                  description: l10n.tripOverviewBucketListSubtitle,
                  onTap: () {
                    context.go('/trips/${trip.id}/bucket-list');
                  },
                ),
                const SizedBox(height: 12),
                _OverviewActionCard(
                  icon: Icons.grid_view_rounded,
                  title: l10n.tripOverviewMore,
                  description: l10n.tripOverviewMoreSubtitle,
                  onTap: () {
                    context.go('/trips/${trip.id}/more');
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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

class _TripHero extends StatelessWidget {
  const _TripHero({required this.trip, required this.onSettingsPressed});

  final Trip trip;
  final VoidCallback onSettingsPressed;

  static const Color _accentColor = Color(0xFFFF7A3D);
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
                  Color(0xFF100C0A),
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
          child: Icon(icon, color: const Color(0xFFF4E9DA), size: 23),
        ),
      ),
    );
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
  static const Color _accentColor = Color(0xFFFF7A3D);
  static const Color _titleColor = Color(0xFFF4E9DA);
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
          padding: const EdgeInsets.all(16),
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
                  borderRadius: BorderRadius.circular(14),
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
                    const SizedBox(height: 4),
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
              const SizedBox(width: 8),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xFFD96C32)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB7A99B), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
