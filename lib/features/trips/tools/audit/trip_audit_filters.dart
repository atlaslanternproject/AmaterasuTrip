// Filtri dell'Audit Trail con il pannello condiviso dei filtri
// (showAmaterasuFilterSheet, lo stesso delle sezioni): sezione, persona
// (username dei membri), azione e periodo; "Azzera filtri" li toglie.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/widgets/filters/amaterasu_filter_sheet.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_audit_data.dart';
import 'trip_audit_names.dart';
import 'trip_audit_tile.dart';

/// Collections of the sections in the register, in menu order.
const tripAuditSections = [
  'transports',
  'reservations',
  'restaurants',
  'savedPlaces',
  'notes',
  'shoppingItems',
  'checklists',
  'memories',
  'itinerary',
];

int tripAuditActiveCount(TripAuditFilters f) =>
    [f.section, f.actorUid, f.action, f.days].where((v) => v != null).length;

Future<void> showTripAuditFilters(
  BuildContext context, {
  required ValueListenable<TripAuditFilters> filters,
  required Map<String, String?> members,
  required ValueChanged<TripAuditFilters> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  AmaterasuFilterGroup group<T>(
    String id,
    String title,
    T? selected,
    List<(T?, String)> options,
    TripAuditFilters Function(T? value) apply,
    ValueChanged<TripAuditFilters> update,
  ) => AmaterasuFilterGroup(title, [
    for (final (value, label) in options)
      AmaterasuFilterOption(
        key: 'audit-filter-$id-${value ?? 'all'}',
        label: label,
        selected: selected == value,
        onTap: () => update(apply(value)),
      ),
  ]);

  return showAmaterasuFilterSheet<TripAuditFilters>(
    context,
    keyPrefix: 'audit',
    initial: filters.value,
    listenable: filters,
    onChanged: onChanged,
    isActive: (f) => f.isActive,
    cleared: (_) => const TripAuditFilters(),
    groupsOf: (f, update) => [
      group<String>(
        'section',
        l10n.auditFilterSection,
        f.section,
        [
          (null, l10n.auditAll),
          for (final s in tripAuditSections)
            (s, tripAuditSectionLabel(l10n, s)),
        ],
        (v) => f.copy(section: () => v),
        update,
      ),
      group<String>(
        'person',
        l10n.auditFilterPerson,
        f.actorUid,
        [
          (null, l10n.auditAll),
          for (final uid in members.keys)
            (uid, tripAuditName(l10n, members, uid)),
        ],
        (v) => f.copy(actorUid: () => v),
        update,
      ),
      group<String>(
        'action',
        l10n.auditFilterAction,
        f.action,
        [
          (null, l10n.auditAll),
          ('create', l10n.auditActionCreate),
          ('update', l10n.auditActionUpdate),
          ('delete', l10n.auditActionDelete),
        ],
        (v) => f.copy(action: () => v),
        update,
      ),
      group<int>(
        'period',
        l10n.auditFilterPeriod,
        f.days,
        [(null, l10n.auditAll), (7, l10n.auditLast7), (30, l10n.auditLast30)],
        (v) => f.copy(days: () => v),
        update,
      ),
    ],
  );
}
