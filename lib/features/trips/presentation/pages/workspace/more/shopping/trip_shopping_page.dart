// Pagina Shopping del viaggio con due schede: "Acquisti" (cosa comprare,
// per chi, budget, prezzo reale, spesa collegata) e "Valigia" (cosa
// portare, per persona, da spuntare). Scheda scelta ricordata finché si resta.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_packing_tab.dart';
import 'trip_shopping_tab.dart';

class TripShoppingPage extends StatefulWidget {
  const TripShoppingPage({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripShoppingPage> createState() => _TripShoppingPageState();
}

class _TripShoppingPageState extends State<TripShoppingPage> {
  var _packing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SegmentedButton<bool>(
        key: const Key('shopping-tabs'),
        segments: [
          ButtonSegment(
            value: false,
            label: Text(l10n.shoppingTabItems),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
          ButtonSegment(
            value: true,
            label: Text(l10n.shoppingTabPacking),
            icon: const Icon(Icons.luggage_outlined),
          ),
        ],
        selected: {_packing},
        onSelectionChanged: (v) => setState(() => _packing = v.first),
      ),
    );
    return _packing
        ? TripPackingTab(tripId: widget.tripId, tabs: tabs)
        : TripShoppingTab(tripId: widget.tripId, tabs: tabs);
  }
}
