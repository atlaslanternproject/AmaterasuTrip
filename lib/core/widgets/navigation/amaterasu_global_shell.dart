import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'amaterasu_bottom_bar.dart';

/// Shell globale dell'app.
///
/// Gestisce esclusivamente:
/// - HOME
/// - VIAGGI
/// - IMPOSTAZIONI
///
/// Il workspace di un singolo viaggio NON appartiene a questa shell:
/// possiede una propria TripWorkspaceShell e una propria bottom bar.
class AmaterasuGlobalShell extends StatelessWidget {
  const AmaterasuGlobalShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AmaterasuBottomBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
