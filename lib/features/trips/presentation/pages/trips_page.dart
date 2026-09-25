import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/features/trips/models/trip.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import '../widgets/trip_card.dart';
import '../widgets/trip_section_title.dart';

class TripsPage extends ConsumerWidget {
  const TripsPage({super.key});

  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _accentColor = Color(0xFFD96C32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tripsAsync = ref.watch(userTripsProvider);

    return tripsAsync.when(
      data: (trips) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final inProgressTrips = <Trip>[];
        final upcomingTrips = <Trip>[];
        final completedTrips = <Trip>[];

        for (final trip in trips) {
          final startDate = _dateOnly(trip.startDate);

          if (trip.status == TripStatus.closed) {
            completedTrips.add(trip);
          } else if (today.isBefore(startDate)) {
            upcomingTrips.add(trip);
          } else {
            inProgressTrips.add(trip);
          }
        }

        inProgressTrips.sort((a, b) => a.startDate.compareTo(b.startDate));
        upcomingTrips.sort((a, b) => a.startDate.compareTo(b.startDate));
        completedTrips.sort((a, b) => b.startDate.compareTo(a.startDate));

        return _buildTripsPage(
          context,
          l10n,
          today: today,
          inProgressTrips: inProgressTrips,
          upcomingTrips: upcomingTrips,
          completedTrips: completedTrips,
        );
      },
      loading: () => const Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(child: CircularProgressIndicator(color: _accentColor)),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _titleColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripsPage(
    BuildContext context,
    AppLocalizations l10n, {
    required DateTime today,
    required List<Trip> inProgressTrips,
    required List<Trip> upcomingTrips,
    required List<Trip> completedTrips,
  }) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              sliver: SliverToBoxAdapter(child: _buildHeader(context, l10n)),
            ),

            if (inProgressTrips.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: TripSectionTitle(
                    title: l10n.tripsInProgress,
                    icon: Icons.explore_rounded,
                    accentColor: _accentColor,
                  ),
                ),
              ),
              _buildTripList(
                context,
                l10n,
                trips: inProgressTrips,
                status: TripCardStatus.inProgress,
                today: today,
                bottomPadding: 0,
              ),
            ],

            if (upcomingTrips.isNotEmpty) ...[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  inProgressTrips.isNotEmpty ? 28 : 16,
                  20,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: TripSectionTitle(
                    title: l10n.tripsUpcoming,
                    icon: Icons.schedule_rounded,
                    accentColor: const Color(0xFFC8894C),
                  ),
                ),
              ),
              _buildTripList(
                context,
                l10n,
                trips: upcomingTrips,
                status: TripCardStatus.upcoming,
                today: today,
                bottomPadding: 0,
              ),
            ],

            if (completedTrips.isNotEmpty) ...[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  inProgressTrips.isNotEmpty || upcomingTrips.isNotEmpty
                      ? 28
                      : 16,
                  20,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: TripSectionTitle(
                    title: l10n.tripsCompleted,
                    icon: Icons.history_rounded,
                    accentColor: _secondaryTextColor,
                  ),
                ),
              ),
              _buildTripList(
                context,
                l10n,
                trips: completedTrips,
                status: TripCardStatus.completed,
                today: today,
                bottomPadding: 32,
              ),
            ],

            if (completedTrips.isEmpty)
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildTripList(
    BuildContext context,
    AppLocalizations l10n, {
    required List<Trip> trips,
    required TripCardStatus status,
    required DateTime today,
    required double bottomPadding,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
      sliver: SliverList.separated(
        itemCount: trips.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final trip = trips[index];

          return TripCard(
            status: status,
            flag: _flagForDestination(trip.destination),
            title: trip.name,
            date: _formatDateRange(context, trip),
            places: trip.destination,
            footer: _footerForTrip(l10n, trip, status, today),
            progress: _progressForTrip(trip, status, today),
            onTap: () => context.go('/trips/${trip.id}'),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            l10n.tripsTitle,
            style: const TextStyle(
              color: _titleColor,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.7,
            ),
          ),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: () => context.push('/trips/create'),
          style: FilledButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: const Color(0xFFFFF6EC),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            l10n.tripsNewTrip,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  String _footerForTrip(
    AppLocalizations l10n,
    Trip trip,
    TripCardStatus status,
    DateTime today,
  ) {
    switch (status) {
      case TripCardStatus.inProgress:
        final totalDays =
            _dateOnly(
              trip.endDate,
            ).difference(_dateOnly(trip.startDate)).inDays +
            1;

        final currentDay =
            today.difference(_dateOnly(trip.startDate)).inDays + 1;

        return l10n.tripsDayProgress(currentDay.clamp(1, totalDays), totalDays);

      case TripCardStatus.upcoming:
        return l10n.tripsUpcomingStatus;

      case TripCardStatus.completed:
        return l10n.tripsCompletedStatus;
    }
  }

  double _progressForTrip(Trip trip, TripCardStatus status, DateTime today) {
    switch (status) {
      case TripCardStatus.inProgress:
        final startDate = _dateOnly(trip.startDate);
        final endDate = _dateOnly(trip.endDate);

        final totalDays = endDate.difference(startDate).inDays + 1;

        if (totalDays <= 0) {
          return 0;
        }

        final currentDay = today.difference(startDate).inDays + 1;

        return (currentDay / totalDays).clamp(0.0, 1.0);

      case TripCardStatus.upcoming:
        return 0;

      case TripCardStatus.completed:
        return 1;
    }
  }

  String _formatDateRange(BuildContext context, Trip trip) {
    final localizations = MaterialLocalizations.of(context);

    final start = localizations.formatMediumDate(trip.startDate);
    final end = localizations.formatMediumDate(trip.endDate);

    return '$start — $end';
  }

  String _flagForDestination(String destination) {
    if (destination.contains('🇯🇵')) {
      return '🇯🇵';
    }

    return '🌍';
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
