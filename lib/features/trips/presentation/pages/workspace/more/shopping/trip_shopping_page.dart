// Pagina Shopping del viaggio: cosa comprare, per chi, budget, prezzo
// reale e spesa collegata. La lista valigia è passata nella sezione
// Checklist (con import delle vecchie voci).

import 'package:flutter/material.dart';

import 'trip_shopping_tab.dart';

class TripShoppingPage extends StatelessWidget {
  const TripShoppingPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) => TripShoppingTab(tripId: tripId);
}
