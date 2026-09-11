import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/navigation/amaterasu_bottom_bar.dart';
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({
    super.key,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = switch (location) {
      '/home' => 0,
      '/trips' => 1,
      '/settings' => 2,
      _ => 0,
    };
    return Scaffold(
      body: child,
      bottomNavigationBar: AmaterasuBottomBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/trips');
            case 2:
              context.go('/settings');
          }
        },
      ),
    );
  }
}