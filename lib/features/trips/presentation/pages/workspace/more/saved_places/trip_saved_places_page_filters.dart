// Parte di trip_saved_places_page.dart: filtri (categoria, visitato),
// ordine (priorità, nome) e raggruppamento per zona o per giorno, con il
// titolo di gruppo mostrato dall'elenco comune.

// ignore_for_file: invalid_use_of_protected_member
part of 'trip_saved_places_page.dart';

extension _TripSavedPlacesFilters on _TripSavedPlacesPageState {
  List<TripSavedPlace> _sorted(List<TripSavedPlace> items) {
    final shown = _filter.apply(
      items,
      today: DateTime.now(),
      dayOf: (_) => null,
      kindOf: (p) => p.category.code,
      categoriesOf: (p) => p.customCategories,
    );
    shown.removeWhere(
      (p) =>
          (_visited == 'todo' && p.visited) ||
          (_visited == 'done' && !p.visited),
    );
    int byName(TripSavedPlace a, TripSavedPlace b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    int byPriority(TripSavedPlace a, TripSavedPlace b) {
      final rank = TripSectionPriority.rank(
        a.priority,
      ).compareTo(TripSectionPriority.rank(b.priority));
      return rank != 0 ? rank : byName(a, b);
    }

    return shown..sort(switch (_sort) {
      'name' => byName,
      // Places without area or day go last.
      'area' => (a, b) {
        final area = (a.area ?? '\u{10FFFF}').toLowerCase().compareTo(
          (b.area ?? '\u{10FFFF}').toLowerCase(),
        );
        return area != 0 ? area : byPriority(a, b);
      },
      'day' => (a, b) {
        final far = DateTime(9999);
        final day = (a.plannedDay ?? far).compareTo(b.plannedDay ?? far);
        return day != 0 ? day : byPriority(a, b);
      },
      _ => byPriority,
    });
  }

  /// Group titles when grouping by area or by day.
  String Function(TripSavedPlace)? _groupOf(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (_sort) {
      'area' => (p) => p.area ?? l10n.savedPlaceNoArea,
      'day' =>
        (p) => p.plannedDay == null
            ? l10n.savedPlaceNoDay
            : AmaterasuDates.day(context, p.plannedDay!, full: true),
      _ => null,
    };
  }

  List<TripSectionFilterGroup> _groups(
    AppLocalizations l10n,
    List<TripSavedPlace> items,
  ) => [
    ...tripSectionFilterGroups(
      l10n,
      _filter,
      (f) => setState(() => _filter = f),
      kinds: [
        for (final c in TripSavedPlaceCategory.values)
          (c.code, TripSavedPlaceLabels.category(c, l10n)),
      ],
      dated: false,
      customCategories: tripSectionUsedCategories(
        items,
        (p) => p.customCategories,
      ),
    ),
    TripSectionFilterGroup(
      id: 'visited',
      title: l10n.savedPlaceVisited,
      options: [
        ('all', l10n.sectionsAll),
        ('todo', l10n.savedPlaceFilterTodo),
        ('done', l10n.savedPlaceFilterDone),
      ],
      selected: _visited,
      onSelected: (v) => setState(() => _visited = v),
    ),
    TripSectionFilterGroup(
      id: 'sort',
      title: l10n.filtersSort,
      isSort: true,
      options: [
        ('priority', l10n.savedPlaceSortPriority),
        ('name', l10n.restaurantSortName),
        ('area', l10n.savedPlaceGroupArea),
        ('day', l10n.savedPlaceGroupDay),
      ],
      selected: _sort,
      onSelected: (v) => setState(() => _sort = v),
    ),
  ];
}
