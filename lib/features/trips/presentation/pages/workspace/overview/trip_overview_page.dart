// Panoramica del viaggio: copertina, stato, date e accesso rapido
// alle sezioni.

import 'package:amaterasutrip/core/widgets/common/amaterasu_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/features/trips/models/trip.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/core/theme/amaterasu_radius.dart';

part 'trip_overview_page_hero.dart';
part 'trip_overview_page_hero_parts.dart';
part 'trip_overview_page_widgets.dart';

class TripOverviewPage extends ConsumerWidget {
  const TripOverviewPage({super.key, required this.tripId});

  final String tripId;

  static const Color _backgroundColor = AmaterasuColors.surfaceDeep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tripAsync = ref.watch(tripProvider(tripId));

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: tripAsync.when(
        loading: () =>
            const Center(child: AmaterasuLoader()),
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

  static const Color _titleColor = AmaterasuColors.textCreamSoft;
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
