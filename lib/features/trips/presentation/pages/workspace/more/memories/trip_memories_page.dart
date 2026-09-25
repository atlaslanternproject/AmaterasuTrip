import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/widgets/trip_placeholder_page.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripMemoriesPage extends StatelessWidget {
  const TripMemoriesPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TripPlaceholderPage(
      title: l10n.tripMemoriesTitle,
      icon: Icons.photo_library_rounded,
      tripId: tripId,
      onBack: () => context.go('/trips/$tripId/more'),
    );
  }
}
