import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

import '../widgets/trip_card.dart';
import '../widgets/trip_section_title.dart';

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _accentColor = Color(0xFFD96C32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              sliver: SliverToBoxAdapter(child: _buildHeader(context, l10n)),
            ),
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: TripCard(
                  status: TripCardStatus.inProgress,
                  flag: '🇯🇵',
                  title: 'Giappone 2027',
                  date: l10n.tripsDayProgress(4, 16),
                  places: 'Kyoto',
                  footer: l10n.tripsTodayActivities(5),
                  progress: 4 / 16,
                  onTap: () => context.push('/trips/japan-2027'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: TripSectionTitle(
                  title: l10n.tripsUpcoming,
                  icon: Icons.schedule_rounded,
                  accentColor: const Color(0xFFC8894C),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: TripCard(
                  status: TripCardStatus.upcoming,
                  flag: '🇯🇵',
                  title: 'Giappone 2028',
                  date: '12 — 27 aprile 2028',
                  places: 'Tokyo · Kyoto · Osaka',
                  footer: l10n.tripsOrganisationProgress(68),
                  progress: 0.68,
                  onTap: () => context.push('/trips/japan-2028'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: TripSectionTitle(
                  title: l10n.tripsCompleted,
                  icon: Icons.history_rounded,
                  accentColor: _secondaryTextColor,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              sliver: SliverToBoxAdapter(
                child: TripCard(
                  status: TripCardStatus.completed,
                  flag: '🇯🇵',
                  title: 'Giappone 2026',
                  date: '3 — 17 ottobre 2026',
                  places: 'Tokyo · Nikko · Kyoto · Osaka',
                  footer: l10n.tripsCompletedStatus,
                  progress: 1,
                  onTap: () => context.push('/trips/japan-2026'),
                ),
              ),
            ),
          ],
        ),
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
}
