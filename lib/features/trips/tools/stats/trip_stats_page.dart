// Pagina "Statistiche" di Altro (tappa 3b): tre numeri (notti, città,
// spese condivise), ciambella e spese per persona dal modulo del budget,
// paesi e città, trasporti per tipo, ristoranti provati e luoghi
// visitati. Solo lettura, dati letti all'apertura della pagina.

import 'package:amaterasutrip/core/widgets/common/amaterasu_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/budget_money_formatter.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/transport/widgets/trip_transport_labels.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_header.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'trip_stats.dart';
import 'trip_stats_data.dart';
import 'trip_stats_expenses.dart';

const _text = TextStyle(color: AmaterasuColors.textPrimary);
const _muted = TextStyle(color: AmaterasuColors.textMuted, fontSize: 12);

class TripStatsPage extends ConsumerWidget {
  const TripStatsPage({super.key, required this.tripId});

  final String tripId;

  Widget _number(String key, String value, String label) => Container(
    key: Key('stats-$key'),
    width: 150,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AmaterasuColors.surfaceRaised,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AmaterasuColors.borderWarm),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AmaterasuColors.accentGold,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label, style: _muted),
      ],
    ),
  );

  Widget _body(BuildContext context, TripStatsData data) {
    final l10n = AppLocalizations.of(context)!;
    final s = TripStats.from(data);
    final e = data.expenses;
    String list(Set<String> values) =>
        values.isEmpty ? l10n.statsNone : (values.toList()..sort()).join(', ');
    return ListView(
      key: const Key('stats-page'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _number('nights', '${s.nights}', l10n.statsNights),
            _number('cities', '${s.cities.length}', l10n.statsCities),
            _number(
              'spent',
              e == null
                  ? '—'
                  : BudgetMoneyFormatter.format(e.totals.total, e.currency),
              l10n.statsSpent,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TripStatsExpenseBlocks(expenses: e),
        TripSectionBlock(
          title: l10n.statsPlaces,
          icon: Icons.public_outlined,
          children: [
            Text(
              list(s.countries),
              key: const Key('stats-countries'),
              style: _text,
            ),
            Text(
              list(s.cities),
              key: const Key('stats-city-list'),
              style: _text,
            ),
            Text(l10n.statsPlacesNote, style: _muted),
          ],
        ),
        TripSectionBlock(
          title: l10n.statsTransports,
          icon: Icons.train_outlined,
          children: [
            if (s.transportsByType.isEmpty) Text(l10n.statsNone, style: _text),
            for (final t in s.transportsByType.entries)
              Row(
                key: Key('stats-transport-${t.key.code}'),
                children: [
                  Icon(
                    TripTransportLabels.icon(t.key),
                    size: 18,
                    color: AmaterasuColors.accentGold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      TripTransportLabels.type(t.key, l10n),
                      style: _text,
                    ),
                  ),
                  Text('${t.value}', style: _text),
                ],
              ),
          ],
        ),
        TripSectionBlock(
          title: l10n.statsFoodAndPlaces,
          icon: Icons.restaurant_outlined,
          children: [
            Text(l10n.statsTried(s.tried, s.restaurants), style: _text),
            if (s.averageRating != null)
              Text(
                l10n.statsRating(s.averageRating!.toStringAsFixed(1)),
                style: _text,
              ),
            Text(l10n.statsVisited(s.visited, s.places), style: _text),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stats = ref.watch(tripStatsProvider(tripId));
    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      body: SafeArea(
        child: Column(
          children: [
            TripSectionHeader(tripId: tripId, title: l10n.statsTitle),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: stats.when(
                    data: (data) => _body(context, data),
                    loading: () => const Center(child: AmaterasuLoader()),
                    error: (_, _) => Center(
                      child: AmaterasuButton.tertiary(
                        key: const Key('stats-retry'),
                        onPressed: () =>
                            ref.invalidate(tripStatsProvider(tripId)),
                        label: '${l10n.statsError} ${l10n.statsRetry}',
                      ),
                    ),
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
