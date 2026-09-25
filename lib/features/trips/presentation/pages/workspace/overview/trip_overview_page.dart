import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/features/trips/models/trip.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/widgets/trip_workspace_card.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/widgets/trip_workspace_header.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripOverviewPage extends ConsumerWidget {
  const TripOverviewPage({super.key, required this.tripId});

  final String tripId;

  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _accentColor = Color(0xFFD96C32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tripAsync = ref.watch(tripProvider(tripId));

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return _buildUnavailablePage(
            context,
            title: l10n.tripOverviewNotFound,
            message: l10n.tripOverviewNotFoundSubtitle,
          );
        }

        return _buildOverview(context, l10n, trip);
      },
      loading: () => Scaffold(
        backgroundColor: _backgroundColor,
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator(color: _accentColor)),
        ),
      ),
      error: (error, stackTrace) => _buildUnavailablePage(
        context,
        title: l10n.tripOverviewError,
        message: error.toString(),
      ),
    );
  }

  Widget _buildOverview(
    BuildContext context,
    AppLocalizations l10n,
    Trip trip,
  ) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.tripOverviewTitle,
                        style: const TextStyle(
                          color: _titleColor,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: TripWorkspaceHeader(
                  title: trip.name,
                  destination: trip.destination,
                  dateRange: _formatDateRange(context, trip),
                  onSettingsTap: () {
                    context.go('/trips/${trip.id}/settings');
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tripOverviewExploreTitle,
                      style: const TextStyle(
                        color: _titleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      l10n.tripOverviewExploreSubtitle,
                      style: const TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              sliver: SliverList.list(
                children: [
                  TripWorkspaceCard(
                    title: l10n.tripOverviewItinerary,
                    subtitle: l10n.tripOverviewItinerarySubtitle,
                    icon: Icons.route_rounded,
                    onTap: () {
                      context.go('/trips/${trip.id}/itinerary');
                    },
                  ),
                  const SizedBox(height: 10),
                  TripWorkspaceCard(
                    title: l10n.tripOverviewBucketList,
                    subtitle: l10n.tripOverviewBucketListSubtitle,
                    icon: Icons.favorite_border_rounded,
                    onTap: () {
                      context.go('/trips/${trip.id}/bucket-list');
                    },
                  ),
                  const SizedBox(height: 10),
                  TripWorkspaceCard(
                    title: l10n.tripOverviewMore,
                    subtitle: l10n.tripOverviewMoreSubtitle,
                    icon: Icons.apps_rounded,
                    onTap: () {
                      context.go('/trips/${trip.id}/more');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailablePage(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: _accentColor,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _titleColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateRange(BuildContext context, Trip trip) {
    final localizations = MaterialLocalizations.of(context);

    final start = localizations.formatMediumDate(trip.startDate);
    final end = localizations.formatMediumDate(trip.endDate);

    return '$start â€” $end';
  }
}
