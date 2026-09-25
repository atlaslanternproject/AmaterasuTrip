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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF080605),
        border: Border(top: BorderSide(color: Color(0xFF3A211B), width: 1)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 88,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            final selected = states.contains(WidgetState.selected);

            return TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? const Color(0xFFFFB06A)
                  : const Color(0xFFE8D8C8),
              letterSpacing: 0.2,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            _navigate(context, index);
          },
          destinations: [
            NavigationDestination(
              icon: const _TripNavIcon(icon: Icons.luggage_outlined),
              selectedIcon: const _TripNavIcon(
                icon: Icons.luggage_rounded,
                selected: true,
              ),
              label: l10n.tripNavTrips,
            ),
            NavigationDestination(
              icon: const _TripNavIcon(icon: Icons.map_outlined),
              selectedIcon: const _TripNavIcon(
                icon: Icons.map_rounded,
                selected: true,
              ),
              label: l10n.tripNavItinerary,
            ),
            NavigationDestination(
              icon: const _TripNavIcon(icon: Icons.favorite_border_rounded),
              selectedIcon: const _TripNavIcon(
                icon: Icons.favorite_rounded,
                selected: true,
              ),
              label: l10n.tripNavBucketList,
            ),
            NavigationDestination(
              icon: const _TripNavIcon(icon: Icons.more_horiz_rounded),
              selectedIcon: const _TripNavIcon(
                icon: Icons.more_horiz_rounded,
                selected: true,
              ),
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

class _TripNavIcon extends StatelessWidget {
  const _TripNavIcon({required this.icon, this.selected = false});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected
        ? const Color(0xFFFF8A4C)
        : const Color(0xFFD9784A);

    if (!selected) {
      return Icon(icon, size: 27, color: iconColor);
    }

    return Icon(
      icon,
      size: 28,
      color: const Color(0xFFFF8A4C),
      shadows: const [Shadow(color: Color(0xFFFF6B32), blurRadius: 4)],
    );
  }
}
