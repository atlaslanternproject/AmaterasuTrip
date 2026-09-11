import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
class AmaterasuBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  const AmaterasuBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.bottomBarHome,
        ),
        NavigationDestination(
          icon: const Icon(Icons.alt_route_outlined),
          selectedIcon: const Icon(Icons.alt_route),
          label: l10n.bottomBarTrips,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.bottomBarSettings,
        ),
      ],
    );
  }
}