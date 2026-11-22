// Elenco dei soggiorni (già filtrati e ordinati), centrato e largo al
// massimo 820 punti (comodo su schermo largo e stretto), con gli avvisi
// delle notti senza alloggio e delle sovrapposizioni in cima. Ogni alloggio appare come card grande,
// card compatta o riga, secondo la modalità scelta (Card, Elenco, Dettagli). Le card si costruiscono solo quando
// stanno per apparire (ListView), così le foto si chiedono al bisogno.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_overlaps.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stays_view.dart';
import 'trip_stay_card.dart';
import 'trip_stay_card_menu.dart';
import 'trip_stay_compact_card.dart';
import 'trip_stay_details_row.dart';
import 'trip_stay_quick_actions.dart';
import 'trip_stays_gaps_banner.dart';
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
    this.expenseOf,
    this.launch,
    this.view = TripStaysView.cards,
    this.today,
    this.uncoveredNights = const [],
  });

  final List<TripStay> stays;
  final String Function(String uid) guestNameOf;
  final bool Function(TripStay stay) canDelete;
  final void Function(TripStay stay)? onEdit;
  final void Function(TripStay stay)? onDelete;
  final Widget? Function(TripStay stay)? footerOf;

  /// Expense as an icon, for the Elenco and Dettagli views.
  final Widget? Function(TripStay stay)? expenseOf;
  final AmaterasuLaunch? launch;
  final TripStaysView view;

  /// "Today" for the free cancellation countdown; tests set it.
  final DateTime? today;

  /// Trip nights without an active stay (all stays, not only the shown).
  final List<DateTime> uncoveredNights;

  @override
  Widget build(BuildContext context) {
    final overlaps = TripStayOverlaps.pairs(stays);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView.separated(
          key: const Key('stays-list'),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          itemCount: stays.length + 1,
          separatorBuilder: (_, index) => SizedBox(
            height: index == 0 ? 0 : (view == TripStaysView.details ? 8 : 12),
          ),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                children: [
                  TripStaysGapsBanner(nights: uncoveredNights),
                  TripStaysOverlapBanner(pairs: overlaps),
                ],
              );
            }
            final stay = stays[index - 1];
            final edit = onEdit == null ? null : () => onEdit!(stay);
            final remove = onDelete == null ? null : () => onDelete!(stay);
            final actions = TripStayQuickActions(
              stay: stay,
              expense: expenseOf?.call(stay),
              onEdit: edit,
              launch: launch,
              menu: TripStayCardMenu(
                stayId: stay.id,
                canEdit: false,
                canDelete: canDelete(stay) && remove != null,
                onDelete: remove,
                dense: true,
              ),
            );
            if (view == TripStaysView.list) {
              return TripStayCompactCard(
                stay: stay,
                actions: actions,
                today: today,
              );
            }
            if (view == TripStaysView.details) {
              return TripStayDetailsRow(
                stay: stay,
                actions: actions,
                today: today,
              );
            }
            return TripStayCard(
              stay: stay,
              guestNames: stay.guestUids.map(guestNameOf).toList(),
              canDelete: canDelete(stay),
              onEdit: onEdit == null ? null : () => onEdit!(stay),
              onDelete: onDelete == null ? null : () => onDelete!(stay),
              footer: footerOf?.call(stay),
              launch: launch,
              today: today,
            );
          },
        ),
      ),
    );
  }
}
