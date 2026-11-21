// Elenco dei soggiorni ordinato per check-in, centrato e largo al massimo
// 820 punti (comodo su schermo largo e stretto), con l'avviso delle
// sovrapposizioni in cima.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_overlaps.dart';
import 'trip_stay_card.dart';
import 'trip_stays_overlap_banner.dart';

class TripStaysList extends StatelessWidget {
  const TripStaysList({
    super.key,
    required this.stays,
    required this.guestNameOf,
    required this.canDelete,
    this.onEdit,
    this.onDelete,
    this.footerOf,
    this.launch,
  });

  final List<TripStay> stays;
  final String Function(String uid) guestNameOf;
  final bool Function(TripStay stay) canDelete;
  final void Function(TripStay stay)? onEdit;
  final void Function(TripStay stay)? onDelete;
  final Widget? Function(TripStay stay)? footerOf;
  final AmaterasuLaunch? launch;

  @override
  Widget build(BuildContext context) {
    final sorted = [...stays]..sort((a, b) {
      final byDay = a.checkInDate.compareTo(b.checkInDate);
      return byDay != 0 ? byDay : a.name.compareTo(b.name);
    });
    final overlaps = TripStayOverlaps.pairs(sorted);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView.separated(
          key: const Key('stays-list'),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          itemCount: sorted.length + 1,
          separatorBuilder: (_, index) =>
              SizedBox(height: index == 0 ? 0 : 12),
          itemBuilder: (context, index) {
            if (index == 0) return TripStaysOverlapBanner(pairs: overlaps);
            final stay = sorted[index - 1];
            return TripStayCard(
              stay: stay,
              guestNames: stay.guestUids.map(guestNameOf).toList(),
              canDelete: canDelete(stay),
              onEdit: onEdit == null ? null : () => onEdit!(stay),
              onDelete: onDelete == null ? null : () => onDelete!(stay),
              footer: footerOf?.call(stay),
              launch: launch,
            );
          },
        ),
      ),
    );
  }
}
