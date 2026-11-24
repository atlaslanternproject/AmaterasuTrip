// Barra sopra l'elenco di una sezione: la barra dei filtri condivisa degli
// alloggi (pulsante "Filtri" con conteggio, pannello, "Azzera filtri") e il
// selettore della vista, ricordata sul dispositivo.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/widgets/filters/amaterasu_filter_bar.dart';
import 'package:amaterasutrip/core/widgets/filters/amaterasu_filter_sheet.dart';
import '../data/trip_section_view_preferences.dart';
import '../models/trip_section_view.dart';
import 'trip_section_view_selector.dart';

/// One group of choices; [selected] is the code of the chosen option and
/// the first option is the default ("all" or the default order).
class TripSectionFilterGroup {
  const TripSectionFilterGroup({
    required this.id,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.isSort = false,
  });

  final String id;
  final String title;
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelected;

  /// Order groups are not counted as filters and show next to the button.
  final bool isSort;

  bool get isActive => !isSort && selected != options.first.$1;
}

class TripSectionToolbar extends StatefulWidget {
  const TripSectionToolbar({
    super.key,
    required this.keyPrefix,
    required this.groups,
    required this.view,
    required this.onView,
    required this.onClear,
    this.shown,
    this.total,
  });

  final String keyPrefix;
  final List<TripSectionFilterGroup> groups;
  final TripSectionView view;
  final ValueChanged<TripSectionView> onView;

  /// Removes every filter and keeps the order.
  final VoidCallback onClear;
  final int? shown;
  final int? total;

  @override
  State<TripSectionToolbar> createState() => _TripSectionToolbarState();
}

class _TripSectionToolbarState extends State<TripSectionToolbar> {
  /// Latest groups, so the open sheet shows the current choices.
  late final _groups = ValueNotifier(widget.groups);

  @override
  void didUpdateWidget(TripSectionToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _groups.value = widget.groups;
    });
  }

  @override
  void dispose() {
    _groups.dispose();
    super.dispose();
  }

  List<AmaterasuFilterGroup> _sheetGroups(
    List<TripSectionFilterGroup> groups,
  ) => [
    for (final group in groups)
      AmaterasuFilterGroup(group.title, [
        for (final (code, label) in group.options)
          AmaterasuFilterOption(
            key: '${widget.keyPrefix}-filter-${group.id}-$code',
            label: label,
            selected: group.selected == code,
            onTap: () => group.onSelected(code),
          ),
      ]),
  ];

  void _open() => showAmaterasuFilterSheet<List<TripSectionFilterGroup>>(
    context,
    keyPrefix: widget.keyPrefix,
    initial: _groups.value,
    listenable: _groups,
    onChanged: (_) {},
    isActive: (groups) => groups.any((g) => g.isActive),
    cleared: (groups) {
      widget.onClear();
      return groups;
    },
    groupsOf: (groups, _) => _sheetGroups(groups),
  );

  @override
  Widget build(BuildContext context) {
    final groups = widget.groups;
    final sort = groups.where((g) => g.isSort).firstOrNull;
    String? sortLabel;
    if (sort != null) {
      sortLabel = sort.options
          .where((o) => o.$1 == sort.selected)
          .map((o) => o.$2)
          .firstOrNull;
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (groups.isNotEmpty)
                AmaterasuFilterBar(
                  keyPrefix: widget.keyPrefix,
                  activeCount: groups.where((g) => g.isActive).length,
                  shown: widget.shown,
                  total: widget.total,
                  sortLabel: sortLabel,
                  onOpen: _open,
                  onClear: widget.onClear,
                  padding: const EdgeInsets.only(bottom: 8),
                ),
              TripSectionViewSelector(
                keyPrefix: widget.keyPrefix,
                view: widget.view,
                onChanged: widget.onView,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loads and saves the chosen view of [section] for this user and trip.
mixin TripSectionViewMemory<W extends StatefulWidget> on State<W> {
  TripSectionView view = TripSectionView.cards;

  String get viewSection;
  String get viewTripId;
  String? get viewUid;

  @override
  void initState() {
    super.initState();
    final uid = viewUid;
    if (uid == null) return;
    TripSectionViewPreferences.load(viewSection, uid, viewTripId).then((saved) {
      if (saved != null && mounted) setState(() => view = saved);
    });
  }

  void changeView(TripSectionView value) {
    setState(() => view = value);
    final uid = viewUid;
    if (uid != null) {
      TripSectionViewPreferences.save(viewSection, uid, viewTripId, value);
    }
  }
}
