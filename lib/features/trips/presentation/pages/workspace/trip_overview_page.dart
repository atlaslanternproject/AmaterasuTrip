import 'package:flutter/material.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

class TripOverviewPage extends StatelessWidget {
  const TripOverviewPage({super.key, required this.tripId});

  final String tripId;

  static const Color _backgroundColor = AmaterasuColors.surfaceDeep;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _backgroundColor,
      body: SizedBox.shrink(),
    );
  }
}
