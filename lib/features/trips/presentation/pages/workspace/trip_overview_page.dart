// Vecchia pagina panoramica vuota (Scaffold senza contenuto), non importata
// da nessun file: la panoramica vera è in overview/trip_overview_page.dart.

import 'package:flutter/material.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

// TODO(audit): C1 pagina vuota non importata da nessun file: eliminarla (la panoramica vera è in overview/).
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
