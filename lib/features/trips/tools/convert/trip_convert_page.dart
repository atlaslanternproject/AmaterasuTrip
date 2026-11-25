// Pagina "Converti" di Altro (nuova tappa 1): valute con i tassi del budget
// (dalla valuta del viaggio a quella di Aspetto), unità, taglie delle
// scarpe e mancia. Solo calcoli: nessun dato salvato.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_appearance_provider.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_display_amount.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_header.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_convert_currency_block.dart';
import 'trip_convert_tip_block.dart';
import 'trip_convert_units_block.dart';

class TripConvertPage extends ConsumerWidget {
  const TripConvertPage({super.key, required this.tripId, this.loader});

  final String tripId;

  /// Replaces the network rate in tests.
  final BudgetQuoteLoader? loader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final trip =
        ref.watch(tripStaysTripInfoProvider(tripId))?.currency ?? 'EUR';
    final shown = ref.watch(amaterasuAppearanceProvider).shownCurrency;
    final to = shown == null || shown == trip ? 'EUR' : shown;
    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      body: SafeArea(
        child: Column(
          children: [
            TripSectionHeader(tripId: tripId, title: l10n.convertTitle),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: ListView(
                    key: const Key('convert-page'),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      TripConvertCurrencyBlock(
                        from: trip,
                        to: to == trip ? 'USD' : to,
                        loader: loader,
                      ),
                      const TripConvertUnitsBlock(),
                      const TripConvertSizesBlock(),
                      TripConvertTipBlock(currency: trip),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
