import 'package:flutter/material.dart';

import 'trip_workspace_bottom_bar.dart';

/// Shell persistente di tutte le pagine appartenenti a un singolo viaggio.
///
/// La bottom bar del workspace viene montata qui una sola volta.
/// Le pagine interne cambiano nel [child], mentre la navigazione principale
/// del viaggio rimane nella shell.
class TripWorkspaceShell extends StatelessWidget {
  const TripWorkspaceShell({
    super.key,
    required this.tripId,
    required this.location,
    required this.child,
  });

  final String tripId;
  final String location;
  final Widget child;

  static const Color _backgroundColor = Color(0xFF100C0A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: child,
      bottomNavigationBar: TripWorkspaceBottomBar(
        tripId: tripId,
        currentSection: _currentSection,
      ),
    );
  }

  TripWorkspaceSection get _currentSection {
    if (location == '/trips/$tripId') {
      return TripWorkspaceSection.overview;
    }

    if (location == '/trips/$tripId/itinerary') {
      return TripWorkspaceSection.itinerary;
    }

    if (location == '/trips/$tripId/bucket-list') {
      return TripWorkspaceSection.bucketList;
    }

    // Tutto ciò che non appartiene alle tre sezioni principali
    // fa parte di "Altro":
    //
    // /more
    // /more/...
    // /settings
    // /settings/...
    return TripWorkspaceSection.more;
  }
}
