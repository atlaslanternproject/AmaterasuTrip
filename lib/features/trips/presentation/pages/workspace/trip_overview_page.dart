import 'package:flutter/material.dart';

class TripOverviewPage extends StatelessWidget {
  const TripOverviewPage({super.key});

  static const Color _backgroundColor = Color(0xFF100C0A);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _backgroundColor,
      body: SizedBox.shrink(),
    );
  }
}
