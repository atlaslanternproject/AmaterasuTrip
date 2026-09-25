import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/widgets/trip_placeholder_page.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/widgets/trip_workspace_bottom_bar.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripNotificationsSettingsPage extends StatelessWidget {
  const TripNotificationsSettingsPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TripPlaceholderPage(
      title: l10n.tripSettingsNotifications,
      icon: Icons.notifications_none_rounded,
      tripId: tripId,
      onBack: () => context.go('/trips/$tripId/settings'),
      bottomNavigationBar: TripWorkspaceBottomBar(
        tripId: tripId,
        currentSection: TripWorkspaceSection.more,
      ),
    );
  }
}
