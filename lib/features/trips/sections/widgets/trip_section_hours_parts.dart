// Pezzi del pannello "Orari e prezzi" delle sezioni: avviso se il giorno o
// l'ora previsti risultano chiusi e fascia di prezzo di Google con la
// conversione nella valuta del viaggio (cambio letto solo qui).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/places/amaterasu_place_hours.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/data/budget_fx_service.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_section_hours_sheet.dart';

/// Only informative: the booking is never blocked.
List<Widget> tripSectionClosedWarning(
  BuildContext context,
  TripSectionHoursTarget target,
  AmaterasuPlaceHours? hours,
) {
  final day = target.day;
  if (day == null || hours == null) return const [];
  final l10n = AppLocalizations.of(context)!;
  final date = MaterialLocalizations.of(context).formatMediumDate(day);
  final time = target.time;
  final String? text;
  if (hours.closedOn(day) == true) {
    text = l10n.sectionsClosedDay(date);
  } else if (hours.closedAt(day, time) == true) {
    text = l10n.sectionsClosedTime(date, time!);
  } else {
    text = null;
  }
  if (text == null) return const [];
  return [
    Container(
      key: Key('${target.keyPrefix}-closed-${target.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AmaterasuColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AmaterasuColors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AmaterasuColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  ];
}

String _range(int? start, int? end, String currency) =>
    '${{?start, ?end}.join('–')} $currency';

class TripSectionGooglePrice extends StatelessWidget {
  const TripSectionGooglePrice({
    super.key,
    required this.range,
    required this.tripCurrency,
    required this.fx,
  });

  final AmaterasuPriceRange range;
  final String tripCurrency;
  final BudgetFxService fx;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final original = _range(range.start, range.end, range.currency);
    final same = range.currency == tripCurrency;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.sectionsGooglePrice(original),
          key: const Key('sections-google-price'),
          style: const TextStyle(color: AmaterasuColors.accentGold),
        ),
        if (!same)
          FutureBuilder(
            future: fx.latest(range.currency, tripCurrency),
            builder: (context, snap) {
              final rate = snap.data?.rate;
              if (rate == null) return const SizedBox.shrink();
              int? convert(int? v) => v == null ? null : (v * rate).round();
              return Text(
                l10n.sectionsGooglePriceConverted(
                  _range(
                    convert(range.start),
                    convert(range.end),
                    tripCurrency,
                  ),
                ),
                key: const Key('sections-google-price-converted'),
                style: const TextStyle(color: AmaterasuColors.textSecondary),
              );
            },
          ),
      ],
    );
  }
}
