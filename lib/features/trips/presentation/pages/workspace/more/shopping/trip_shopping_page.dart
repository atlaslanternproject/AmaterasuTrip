import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/widgets/trip_placeholder_page.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripShoppingPage extends StatelessWidget {
  const TripShoppingPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TripPlaceholderPage(
      title: l10n.tripShoppingTitle,
      icon: Icons.shopping_bag_rounded,
      tripId: tripId,
      onBack: () => context.go('/trips/$tripId/more'),
    );
  }
}
