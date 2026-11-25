// Pagina "Esporta" di Altro (tappa 3a): calendario .ics con la scelta di
// alloggi, trasporti, prenotazioni e ristoranti; i dati si leggono solo
// premendo "Scarica" e il file si scarica dal browser (lib/core/files).
// Nessun dato salvato, nessuna API.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/files/amaterasu_files.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_primary_button.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_header.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_export_data.dart';
import 'trip_ics_events.dart';
import 'trip_ics_writer.dart';

typedef TripExportDownload =
    bool Function(String name, String mime, String text);

class TripExportPage extends ConsumerStatefulWidget {
  const TripExportPage({
    super.key,
    required this.tripId,
    this.download = amaterasuDownloadText,
    this.offsetOf,
  });

  final String tripId;
  final TripExportDownload download;

  /// Replaces the browser time zones in tests.
  final TripIcsOffsetOf? offsetOf;

  @override
  ConsumerState<TripExportPage> createState() => _TripExportPageState();
}

class _TripExportPageState extends ConsumerState<TripExportPage> {
  final _chosen = {...TripIcsCategory.values};
  bool _busy = false;

  String _label(AppLocalizations l10n, TripIcsCategory c) => switch (c) {
    TripIcsCategory.stays => l10n.tripMoreHotels,
    TripIcsCategory.transports => l10n.tripMoreTransport,
    TripIcsCategory.reservations => l10n.tripMoreBookings,
    TripIcsCategory.restaurants => l10n.tripMoreRestaurants,
  };

  Future<void> _downloadIcs() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final name =
        ref.read(tripProvider(widget.tripId)).asData?.value?.name ?? 'Viaggio';
    setState(() => _busy = true);
    try {
      final data = await ref.read(tripExportLoaderProvider)(widget.tripId);
      final build = TripIcsEvents(l10n, offsetOf: widget.offsetOf);
      final events = [
        if (_chosen.contains(TripIcsCategory.stays)) ...build.stays(data.stays),
        if (_chosen.contains(TripIcsCategory.transports))
          ...build.transports(data.transports),
        if (_chosen.contains(TripIcsCategory.reservations))
          ...build.reservations(data.reservations),
        if (_chosen.contains(TripIcsCategory.restaurants))
          ...build.restaurants(data.restaurants),
      ];
      if (events.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.exportIcsEmpty)));
        return;
      }
      final text = TripIcsWriter.write(
        name: name,
        events: events,
        now: DateTime.now(),
      );
      final slug = name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      final file = 'amaterasu-${slug.isEmpty ? 'viaggio' : slug}.ics';
      final ok = widget.download(file, 'text/calendar;charset=utf-8', text);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok ? l10n.exportIcsDone(events.length) : l10n.exportIcsFailed,
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportIcsFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      body: SafeArea(
        child: Column(
          children: [
            TripSectionHeader(tripId: widget.tripId, title: l10n.exportTitle),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: ListView(
                    key: const Key('export-page'),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      TripSectionBlock(
                        title: l10n.exportIcs,
                        icon: Icons.event_outlined,
                        children: [
                          Text(
                            l10n.exportIcsBody,
                            style: const TextStyle(
                              color: AmaterasuColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.exportIcsPick,
                            style: const TextStyle(
                              color: AmaterasuColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              for (final c in TripIcsCategory.values)
                                FilterChip(
                                  key: Key('export-ics-${c.name}'),
                                  label: Text(_label(l10n, c)),
                                  selected: _chosen.contains(c),
                                  selectedColor: AmaterasuColors.accentBudget
                                      .withValues(alpha: 0.25),
                                  onSelected: (on) => setState(
                                    () =>
                                        on ? _chosen.add(c) : _chosen.remove(c),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AmaterasuPrimaryButton(
                            key: const Key('export-ics-download'),
                            text: l10n.exportIcsDownload,
                            icon: const Icon(Icons.download_rounded),
                            loading: _busy,
                            onPressed: _chosen.isEmpty || _busy
                                ? null
                                : _downloadIcs,
                          ),
                        ],
                      ),
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
