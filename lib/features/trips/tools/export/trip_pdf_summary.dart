// Riepilogo del viaggio da stampare o salvare come PDF (tappa 3c): titolo,
// destinazione e date, tabelle di alloggi, trasporti, prenotazioni e
// ristoranti prenotati in ordine di data (annullati esclusi) e i link dei
// ricordi (cartella del viaggio e album). Solo testo HTML, nessun dato salvato.

import 'dart:convert';

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/transport/widgets/trip_transport_labels.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_export_data.dart';

/// Trip fields shown at the top.
class TripPdfTrip {
  const TripPdfTrip({
    required this.name,
    required this.destination,
    required this.start,
    required this.end,
    this.folderUrl,
  });

  final String name, destination;
  final DateTime start, end;

  /// Google Drive folder of the trip (memories), if any.
  final String? folderUrl;
}

abstract final class TripPdfSummary {
  static const _esc = HtmlEscape(HtmlEscapeMode.attribute);

  // TODO(audit): stesso stile delle stampe del budget e delle checklist;
  // unificarle in un modulo comune nel giro finale (budget approvato).
  static const _style =
      'body{font-family:sans-serif;font-size:11px;margin:16px}'
      'h1{font-size:18px;margin-bottom:2px}h2{font-size:14px;margin:18px 0 6px}'
      'table{border-collapse:collapse;width:100%;margin-bottom:12px}'
      'th,td{border:1px solid #999;padding:4px;text-align:left;'
      'vertical-align:top}th{background:#eee}.muted{color:#555}';

  static String _link(String url, String label) {
    final ok = url.startsWith('https://') || url.startsWith('http://');
    return ok
        ? '<a href="${_esc.convert(url)}">${_esc.convert(label)}</a>'
        : _esc.convert(label);
  }

  static String html({
    required TripPdfTrip trip,
    required TripExportData data,
    required AppLocalizations l10n,
    required String Function(DateTime day) dayOf,
    required String Function(String hhmm) timeOf,
    required DateTime now,
  }) {
    String when(DateTime? day, String? time) => day == null
        ? ''
        : [dayOf(day), if (time != null) timeOf(time)].join(' ');
    final out = StringBuffer();
    void table(String title, List<String> header, List<List<String>> rows) {
      if (rows.isEmpty) return;
      out.write('<h2>${_esc.convert(title)}</h2><table><thead><tr>');
      for (final h in header) {
        out.write('<th>${_esc.convert(h)}</th>');
      }
      out.write('</tr></thead><tbody>');
      for (final row in rows) {
        out.write(
          '<tr>${row.map((c) => '<td>${_esc.convert(c)}</td>').join()}</tr>',
        );
      }
      out.write('</tbody></table>');
    }

    final stays =
        data.stays.where((s) => s.status != TripStayStatus.cancelled).toList()
          ..sort((a, b) => a.checkInDate.compareTo(b.checkInDate));
    table(
      l10n.tripMoreHotels,
      [
        l10n.exportPdfName,
        'Check-in',
        'Check-out',
        l10n.statsNights,
        l10n.exportPdfPlace,
        l10n.exportPdfCode,
      ],
      [
        for (final s in stays)
          [
            s.name,
            when(s.checkInDate, s.checkInTime),
            when(s.checkOutDate, s.checkOutTime),
            '${s.nights}',
            s.address ?? s.city ?? '',
            s.confirmationCode ?? '',
          ],
      ],
    );
    final transports =
        data.transports
            .where((t) => t.status != TripBookingStatus.cancelled)
            .toList()
          ..sort((a, b) => a.departureDate.compareTo(b.departureDate));
    table(
      l10n.tripMoreTransport,
      [
        l10n.exportPdfName,
        l10n.exportPdfRoute,
        l10n.exportPdfDeparture,
        l10n.exportPdfArrival,
        l10n.exportPdfCode,
      ],
      [
        for (final t in transports)
          [
            TripTransportLabels.title(t, l10n),
            t.route,
            when(t.departureDate, t.departureTime),
            when(t.arrivalDate, t.arrivalTime),
            t.bookingCode ?? '',
          ],
      ],
    );
    final reservations =
        data.reservations
            .where((r) => r.status != TripBookingStatus.cancelled)
            .toList()
          ..sort((a, b) => (a.date ?? now).compareTo(b.date ?? now));
    table(
      l10n.tripMoreBookings,
      [
        l10n.exportPdfName,
        l10n.exportPdfWhen,
        l10n.exportPdfPlace,
        l10n.exportPdfCode,
      ],
      [
        for (final r in reservations)
          [
            r.name,
            when(r.date, r.time),
            r.place.name ?? r.place.address ?? '',
            r.bookingCode ?? '',
          ],
      ],
    );
    final restaurants =
        data.restaurants.where((r) => r.reservationDate != null).toList()
          ..sort((a, b) => a.reservationDate!.compareTo(b.reservationDate!));
    table(
      l10n.tripMoreRestaurants,
      [l10n.exportPdfName, l10n.exportPdfWhen, l10n.exportPdfPlace],
      [
        for (final r in restaurants)
          [
            r.name,
            when(r.reservationDate, r.reservationTime),
            r.place.name ?? r.place.address ?? '',
          ],
      ],
    );
    final albums = data.memories.where((m) => m.isAlbum && m.url != null);
    final folder = trip.folderUrl;
    if (folder != null || albums.isNotEmpty) {
      out.write('<h2>${_esc.convert(l10n.tripMoreMemories)}</h2><ul>');
      if (folder != null) {
        out.write(
          '<li>${_link(folder, l10n.exportPdfFolder)}: '
          '${_esc.convert(folder)}</li>',
        );
      }
      for (final a in albums) {
        out.write(
          '<li>${_link(a.url!, a.title ?? a.url!)}: '
          '${_esc.convert(a.url!)}</li>',
        );
      }
      out.write('</ul>');
    }
    final title = _esc.convert(trip.name);
    return '<!doctype html><html><head><meta charset="utf-8">'
        '<title>$title</title><style>$_style</style></head><body>'
        '<h1>$title</h1><div class="muted">'
        '${_esc.convert('${trip.destination} · ${dayOf(trip.start)} - ${dayOf(trip.end)}')}'
        '<br>${_esc.convert(l10n.exportPdfGenerated(dayOf(now)))}</div>'
        '$out</body></html>';
  }
}
