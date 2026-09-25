import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/widgets/trip_placeholder_page.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/widgets/trip_workspace_bottom_bar.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripItineraryPage extends StatelessWidget {
  const TripItineraryPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TripPlaceholderPage(
      title: l10n.tripNavItinerary,
      icon: Icons.map_rounded,
      tripId: tripId,
      onBack: () => context.go('/trips/$tripId'),
      bottomNavigationBar: TripWorkspaceBottomBar(
        tripId: tripId,
        currentSection: TripWorkspaceSection.itinerary,
      ),
    );
  }
}
