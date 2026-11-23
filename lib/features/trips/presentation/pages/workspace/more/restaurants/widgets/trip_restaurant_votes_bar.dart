// Voti di un ristorante nella card, con la stessa idea della bucket list:
// il proprio voto (SS, S, A, B; toccandolo di nuovo lo si toglie) e quanti
// viaggiatori hanno scelto ogni livello.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_votes.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripRestaurantVotesBar extends StatelessWidget {
  const TripRestaurantVotesBar({
    super.key,
    required this.item,
    required this.uid,
    required this.onVote,
  });

  final TripRestaurant item;
  final String? uid;
  final void Function(String? level) onVote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mine = item.votes[uid];
    final counts = TripRestaurantVotes.counts(item.votes);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.restaurantVotesTitle(item.votes.length),
            style: const TextStyle(
              color: AmaterasuColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final level in TripRestaurantVotes.levels)
                ChoiceChip(
                  key: Key('restaurant-vote-${item.id}-$level'),
                  label: Text('$level · ${counts[level]}'),
                  selected: mine == level,
                  selectedColor: AmaterasuColors.accentBudget.withValues(
                    alpha: 0.3,
                  ),
                  onSelected: uid == null
                      ? null
                      : (on) => onVote(on ? level : null),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
