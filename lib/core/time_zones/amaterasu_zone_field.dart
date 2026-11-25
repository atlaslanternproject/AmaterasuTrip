// Selettore del fuso orario per città, con lo stesso aspetto del selettore
// valuta: pulsante a contorno "Fuso: Roma, ora locale 14:32" che apre un
// pannello dal basso con ricerca della città (al tocco di "Cerca") e
// l'elenco dei risultati con il loro fuso. Si può anche togliere.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'amaterasu_zone_clock.dart';
import 'amaterasu_zone_search.dart';

/// Chosen zone: IANA name and the city written for the user.
class AmaterasuZoneValue {
  const AmaterasuZoneValue({required this.zone, this.city});

  final String zone;
  final String? city;
}

class AmaterasuZoneField extends StatelessWidget {
  const AmaterasuZoneField({
    super.key,
    required this.keyPrefix,
    required this.label,
    required this.value,
    required this.onChanged,
    this.fallback,
  });

  final String keyPrefix;
  final String label;
  final AmaterasuZoneValue? value;
  final ValueChanged<AmaterasuZoneValue?> onChanged;

  /// Shown when there is no zone yet (e.g. an old "UTC+01:00").
  final String? fallback;

  /// "Roma, ora locale 14:32" (or the zone name when there is no city).
  static String describe(AmaterasuZoneValue value, AppLocalizations l10n) {
    final place = value.city ?? value.zone.replaceAll('_', ' ');
    final time = AmaterasuZoneClock.localTimeNow(value.zone);
    return time == null ? place : l10n.zoneLocalTime(place, time);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = value;
    final text = current == null
        ? (fallback ?? l10n.zoneNone)
        : describe(current, l10n);
    return Row(
      children: [
        Flexible(
          child: OutlinedButton.icon(
            key: Key('$keyPrefix-zone'),
            onPressed: () async {
              final picked = await showModalBottomSheet<AmaterasuZoneValue>(
                context: context,
                isScrollControlled: true,
                backgroundColor: AmaterasuColors.surfaceCard,
                builder: (_) => _ZoneSheet(keyPrefix: keyPrefix),
              );
              if (picked != null) onChanged(picked);
            },
            icon: const Icon(Icons.public_rounded),
            label: Text('$label: $text', overflow: TextOverflow.ellipsis),
          ),
        ),
        if (current != null)
          IconButton(
            key: Key('$keyPrefix-zone-clear'),
            tooltip: l10n.zoneRemove,
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.close_rounded),
          ),
      ],
    );
  }
}

class _ZoneSheet extends ConsumerStatefulWidget {
  const _ZoneSheet({required this.keyPrefix});

  final String keyPrefix;

  @override
  ConsumerState<_ZoneSheet> createState() => _ZoneSheetState();
}

class _ZoneSheetState extends ConsumerState<_ZoneSheet> {
  final _query = TextEditingController();
  Future<List<AmaterasuZoneCity>>? _results;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search() => setState(() {
    _results = ref
        .read(amaterasuZoneSearchProvider)
        .search(_query.text, Localizations.localeOf(context).languageCode);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = widget.keyPrefix;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.zoneSheetTitle,
            style: const TextStyle(
              color: AmaterasuColors.textCream,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: Key('$p-zone-search'),
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: l10n.zoneSearchHint,
              suffixIcon: IconButton(
                key: Key('$p-zone-search-go'),
                tooltip: l10n.zoneSearch,
                onPressed: _search,
                icon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_results != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: FutureBuilder(
                future: _results,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final list = snap.data ?? const [];
                  if (snap.hasError || list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        snap.hasError
                            ? l10n.zoneSearchError
                            : l10n.zoneNoResults,
                      ),
                    );
                  }
                  return Material(
                    type: MaterialType.transparency,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final (i, city) in list.indexed)
                          ListTile(
                            key: Key('$p-zone-result-$i'),
                            leading: const Icon(Icons.location_city_rounded),
                            title: Text(city.name),
                            subtitle: Text(
                              [
                                if (city.place.isNotEmpty) city.place,
                                city.zone,
                              ].join(' · '),
                            ),
                            onTap: () => Navigator.pop(
                              context,
                              AmaterasuZoneValue(
                                zone: city.zone,
                                city: city.name,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
