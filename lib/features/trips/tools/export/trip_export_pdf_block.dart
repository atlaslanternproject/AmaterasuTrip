// Blocco "PDF del viaggio" della pagina Esporta (tappa 3c): legge i dati
// solo premendo il pulsante e apre il riepilogo in una nuova scheda da
// stampare o salvare come PDF (lib/core/files); avviso se il browser blocca
// la scheda. Date e ore nel formato scelto in Aspetto.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/core/files/amaterasu_files.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_primary_button.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_export_data.dart';
import 'trip_pdf_summary.dart';

class TripExportPdfBlock extends ConsumerStatefulWidget {
  const TripExportPdfBlock({
    super.key,
    required this.tripId,
    this.print = amaterasuPrintHtml,
  });

  final String tripId;

  /// Opens the page to print; replaced in tests.
  final bool Function(String html) print;

  @override
  ConsumerState<TripExportPdfBlock> createState() => _TripExportPdfBlockState();
}

class _TripExportPdfBlockState extends ConsumerState<TripExportPdfBlock> {
  bool _busy = false;

  Future<void> _open() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final trip = ref.read(tripProvider(widget.tripId)).asData?.value;
    if (trip == null) return;
    setState(() => _busy = true);
    try {
      final data = await ref.read(tripExportLoaderProvider)(widget.tripId);
      if (!mounted) return;
      final html = TripPdfSummary.html(
        trip: TripPdfTrip(
          name: trip.name,
          destination: trip.destination,
          start: trip.startDate,
          end: trip.endDate,
          folderUrl: trip.cloudArchive?.folderUrl,
        ),
        data: data,
        l10n: l10n,
        dayOf: (d) => AmaterasuDates.day(context, d),
        timeOf: (t) => AmaterasuDates.time(context, t),
        now: DateTime.now(),
      );
      if (!widget.print(html)) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.exportPdfBlocked)));
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportIcsFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ready = ref.watch(tripProvider(widget.tripId)).asData?.value != null;
    return TripSectionBlock(
      title: l10n.exportPdf,
      icon: Icons.picture_as_pdf_outlined,
      children: [
        Text(
          l10n.exportPdfBody,
          style: const TextStyle(color: AmaterasuColors.textSecondary),
        ),
        const SizedBox(height: 16),
        AmaterasuPrimaryButton(
          key: const Key('export-pdf-open'),
          text: l10n.exportPdfButton,
          icon: const Icon(Icons.print_outlined),
          loading: _busy,
          onPressed: !ready || _busy ? null : _open,
        ),
      ],
    );
  }
}
