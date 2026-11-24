// Parte di trip_restaurants_page.dart: filtri (stato, prezzo, allergeni)
// e ordine dei ristoranti (voti, nome, prenotazione).

// ignore_for_file: invalid_use_of_protected_member
part of 'trip_restaurants_page.dart';

extension _TripRestaurantsFilters on _TripRestaurantsPageState {
  List<TripRestaurant> _sorted(List<TripRestaurant> items) {
    final shown = _filter.apply(
      items,
      today: DateTime.now(),
      dayOf: (r) => r.reservationDate,
      timeOf: (r) => r.reservationTime,
      statusOf: (r) => r.status.code,
      kindOf: (r) => '${r.priceLevel ?? 0}',
    );
    shown.removeWhere(
      (r) =>
          (_allergens == 'yes' && r.allergens.isEmpty) ||
          (_allergens == 'no' && r.allergens.isNotEmpty),
    );
    if (_sort == 'date') return shown;
    int byName(TripRestaurant a, TripRestaurant b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return shown..sort(
      _sort == 'name'
          ? byName
          : (a, b) {
              final byVotes = TripRestaurantVotes.average(
                b.votes,
              ).compareTo(TripRestaurantVotes.average(a.votes));
              return byVotes != 0 ? byVotes : byName(a, b);
            },
    );
  }

  List<TripSectionFilterGroup> _groups(AppLocalizations l10n) => [
    ...tripSectionFilterGroups(
      l10n,
      _filter,
      (f) => setState(() => _filter = f),
      statuses: [
        for (final s in TripRestaurantStatus.values)
          (s.code, TripRestaurantLabels.status(s, l10n)),
      ],
      kinds: [
        for (final p in [1, 2, 3, 4]) ('$p', TripRestaurantLabels.price(p)),
      ],
      dated: false,
      kindTitle: l10n.restaurantFilterPrice,
    ),
    TripSectionFilterGroup(
      id: 'allergens',
      title: l10n.restaurantFilterAllergens,
      options: [
        ('all', l10n.sectionsAll),
        ('yes', l10n.restaurantFilterYes),
        ('no', l10n.restaurantFilterNo),
      ],
      selected: _allergens,
      onSelected: (v) => setState(() => _allergens = v),
    ),
    TripSectionFilterGroup(
      id: 'sort',
      title: l10n.filtersSort,
      isSort: true,
      options: [
        ('votes', l10n.restaurantSortVotes),
        ('name', l10n.restaurantSortName),
        ('date', l10n.restaurantSortDate),
      ],
      selected: _sort,
      onSelected: (v) => setState(() => _sort = v),
    ),
  ];
}
