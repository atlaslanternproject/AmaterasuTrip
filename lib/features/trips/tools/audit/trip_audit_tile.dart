// Una voce dell'Audit Trail: icona della sezione (stesse di Cerca), "Yato
// ha modificato «Volo»", sezione con data e ora (formato di Aspetto) e i
// campi cambiati con prima → dopo. Solo lettura: nessun annullamento.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_audit_data.dart';

/// Section of a register entry ("shoppingItems" is the Shopping section).
TripSearchSection? tripAuditSection(String collection) =>
    collection == 'shoppingItems'
    ? TripSearchSection.shopping
    : TripSearchSection.values.where((s) => s.name == collection).firstOrNull;

/// Name of a register collection (the itinerary is not a Cerca section).
String tripAuditSectionLabel(AppLocalizations l10n, String collection) =>
    tripAuditSection(collection)?.label(l10n) ??
    (collection == 'itinerary' ? l10n.tripNavItinerary : collection);

/// Icon of a register collection.
IconData tripAuditSectionIcon(String collection) =>
    tripAuditSection(collection)?.icon ??
    (collection == 'itinerary' ? Icons.route_rounded : Icons.history_rounded);

String tripAuditField(AppLocalizations l10n, String field) => switch (field) {
  'name' => l10n.auditFieldName,
  'title' => l10n.auditFieldTitle,
  'text' || 'body' => l10n.auditFieldText,
  'status' => l10n.auditFieldStatus,
  'date' || 'reservationDate' => l10n.auditFieldDate,
  'time' || 'reservationTime' => l10n.auditFieldTime,
  'notes' => l10n.auditFieldNotes,
  'expenseId' => l10n.auditFieldExpense,
  'items' || 'checklist' => l10n.auditFieldItems,
  'votes' => l10n.auditFieldVotes,
  'bookingCode' || 'confirmationCode' => l10n.auditFieldBookingCode,
  'departureDate' || 'departureTime' => l10n.auditFieldDeparture,
  'arrivalDate' || 'arrivalTime' => l10n.auditFieldArrival,
  'estimatedCostMinorUnits' || 'estimatedCostCurrency' => l10n.auditFieldCost,
  // Other fields: "checkInHoursBefore" -> "check in hours before".
  _ => field.replaceAllMapped(
    RegExp('[A-Z]'),
    (m) => ' ${m[0]!.toLowerCase()}',
  ),
};

class TripAuditTile extends StatelessWidget {
  const TripAuditTile({super.key, required this.entry, required this.who});

  final TripAuditEntry entry;
  final String who;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final at = entry.at;
    final when = at == null
        ? ''
        : '${AmaterasuDates.day(context, at)} '
              '${AmaterasuDates.time(context, '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}')}';
    final verb = switch (entry.action) {
      'create' => l10n.auditCreate(who),
      'delete' => l10n.auditDelete(who),
      _ => l10n.auditUpdate(who),
    };
    String value(String v) => v.isEmpty ? l10n.auditEmptyValue : v;
    const small = TextStyle(color: AmaterasuColors.textMuted, fontSize: 12);
    return Container(
      key: Key('audit-entry-${entry.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AmaterasuColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AmaterasuColors.borderWarm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tripAuditSectionIcon(entry.section),
            color: AmaterasuColors.accentBudget,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$verb «${entry.itemName.isEmpty ? l10n.auditUntitled : entry.itemName}»',
                  style: const TextStyle(
                    color: AmaterasuColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  [
                    tripAuditSectionLabel(l10n, entry.section),
                    when,
                  ].join(' · '),
                  style: small,
                ),
                for (final c in entry.changes)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${tripAuditField(l10n, c.field)}: '
                      '${value(c.before)} → ${value(c.after)}',
                      key: Key('audit-change-${entry.id}-${c.field}'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AmaterasuColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
