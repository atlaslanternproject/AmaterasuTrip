import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

enum TripWorkspaceSection { overview, itinerary, bucketList, more }

class TripWorkspaceBottomBar extends StatelessWidget {
  const TripWorkspaceBottomBar({
    super.key,
    required this.tripId,
    required this.currentSection,
  });

  final String tripId;
  final TripWorkspaceSection currentSection;

  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _borderColor = Color(0xFF5A3023);
  static const Color _accentColor = Color(0xFFD96C32);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        border: Border(
          top: BorderSide(color: _borderColor.withValues(alpha: 0.65)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          indicatorColor: _accentColor.withValues(alpha: 0.14),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            _navigate(context, index);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.luggage_outlined),
              selectedIcon: const Icon(Icons.luggage_rounded),
              label: l10n.tripNavTrips,
            ),
            NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: const Icon(Icons.map_rounded),
              label: l10n.tripNavItinerary,
            ),
            NavigationDestination(
              icon: const Icon(Icons.favorite_border_rounded),
              selectedIcon: const Icon(Icons.favorite_rounded),
              label: l10n.tripNavBucketList,
            ),
            NavigationDestination(
              icon: const Icon(Icons.more_horiz_rounded),
              selectedIcon: const Icon(Icons.more_horiz_rounded),
              label: l10n.tripNavMore,
            ),
          ],
        ),
      ),
    );
  }

  int get _selectedIndex {
    switch (currentSection) {
      case TripWorkspaceSection.overview:
        return 0;
      case TripWorkspaceSection.itinerary:
        return 1;
      case TripWorkspaceSection.bucketList:
        return 2;
      case TripWorkspaceSection.more:
        return 3;
    }
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        if (currentSection == TripWorkspaceSection.overview) {
          context.go('/home', extra: 1);
        } else {
          context.go('/trips/$tripId');
        }
        return;

      case 1:
        if (currentSection != TripWorkspaceSection.itinerary) {
          context.go('/trips/$tripId/itinerary');
        }
        return;

      case 2:
        if (currentSection != TripWorkspaceSection.bucketList) {
          context.go('/trips/$tripId/bucket-list');
        }
        return;

      case 3:
        if (currentSection != TripWorkspaceSection.more) {
          context.go('/trips/$tripId/more');
        }
        return;
    }
  }
}
