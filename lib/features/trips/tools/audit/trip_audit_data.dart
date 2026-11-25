// Audit Trail (v1.58.0): una voce del registro trips/{tripId}/auditTrail
// (chi, cosa, quando, prima/dopo), i filtri (sezione, persona, azione,
// periodo) e la lettura a pagine da 30, solo su richiesta: nessun ascolto
// sempre attivo. Il registro lo scrive solo il server.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripAuditEntry {
  const TripAuditEntry({
    required this.id,
    required this.section,
    required this.itemId,
    required this.itemName,
    required this.action,
    this.actorUid,
    this.at,
    this.changes = const [],
  });

  factory TripAuditEntry.fromMap(String id, Map<String, dynamic> m) {
    final raw = m['changes'];
    String text(Object? v) => v == null ? '' : '$v';
    return TripAuditEntry(
      id: id,
      section: text(m['section']),
      itemId: text(m['itemId']),
      itemName: text(m['itemName']),
      action: text(m['action']),
      actorUid: m['actorUid'] as String?,
      at: (m['at'] as Timestamp?)?.toDate(),
      changes: [
        if (raw is Map)
          for (final e in raw.entries)
            if (e.value is Map)
              (
                field: '${e.key}',
                before: text((e.value as Map)['before']),
                after: text((e.value as Map)['after']),
              ),
      ],
    );
  }

  final String id, section, itemId, itemName, action;
  final String? actorUid;
  final DateTime? at;
  final List<({String field, String before, String after})> changes;
}

/// Filters of the register; null means "all".
class TripAuditFilters {
  const TripAuditFilters({this.section, this.actorUid, this.action, this.days});

  final String? section, actorUid, action;

  /// Last N days (7 or 30); null: the whole trip.
  final int? days;

  TripAuditFilters copy({
    String? Function()? section,
    String? Function()? actorUid,
    String? Function()? action,
    int? Function()? days,
  }) => TripAuditFilters(
    section: section == null ? this.section : section(),
    actorUid: actorUid == null ? this.actorUid : actorUid(),
    action: action == null ? this.action : action(),
    days: days == null ? this.days : days(),
  );

  bool get isActive =>
      section != null || actorUid != null || action != null || days != null;
}

typedef TripAuditChunk = ({List<TripAuditEntry> entries, Object? next});

abstract interface class TripAuditSource {
  /// One page of 30; [after] is the `next` of the previous page.
  Future<TripAuditChunk> page(
    String tripId,
    TripAuditFilters filters, {
    Object? after,
    DateTime? now,
  });
}

class FirestoreTripAuditSource implements TripAuditSource {
  FirestoreTripAuditSource(this._firestore);

  static const pageSize = 30;
  final FirebaseFirestore _firestore;

  @override
  Future<TripAuditChunk> page(
    String tripId,
    TripAuditFilters filters, {
    Object? after,
    DateTime? now,
  }) async {
    Query<Map<String, dynamic>> q = _firestore.collection(
      'trips/$tripId/auditTrail',
    );
    if (filters.section != null) {
      q = q.where('section', isEqualTo: filters.section);
    }
    if (filters.actorUid != null) {
      q = q.where('actorUid', isEqualTo: filters.actorUid);
    }
    if (filters.action != null) {
      q = q.where('action', isEqualTo: filters.action);
    }
    if (filters.days != null) {
      final from = (now ?? DateTime.now()).subtract(
        Duration(days: filters.days!),
      );
      q = q.where('at', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    q = q.orderBy('at', descending: true).limit(pageSize);
    if (after is DocumentSnapshot) q = q.startAfterDocument(after);
    final snap = await q.get();
    return (
      entries: [
        for (final d in snap.docs) TripAuditEntry.fromMap(d.id, d.data()),
      ],
      next: snap.docs.length == pageSize ? snap.docs.last : null,
    );
  }
}

final tripAuditSourceProvider = Provider<TripAuditSource>(
  (ref) => FirestoreTripAuditSource(FirebaseFirestore.instance),
);
