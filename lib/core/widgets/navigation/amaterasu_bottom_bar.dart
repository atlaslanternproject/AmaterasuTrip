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
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            NavigationDestination(
              icon: const _AmaterasuNavIcon(icon: Icons.home_outlined),
              selectedIcon: const _AmaterasuNavIcon(
                icon: Icons.home,
                selected: true,
              ),
              label: l10n.bottomBarHome,
            ),
            NavigationDestination(
              icon: const _AmaterasuNavIcon(icon: Icons.alt_route_outlined),
              selectedIcon: const _AmaterasuNavIcon(
                icon: Icons.alt_route,
                selected: true,
              ),
              label: l10n.bottomBarTrips,
            ),
            NavigationDestination(
              icon: const _AmaterasuNavIcon(icon: Icons.settings_outlined),
              selectedIcon: const _AmaterasuNavIcon(
                icon: Icons.settings,
                selected: true,
              ),
              label: l10n.bottomBarSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmaterasuNavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  const _AmaterasuNavIcon({required this.icon, this.selected = false});
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
