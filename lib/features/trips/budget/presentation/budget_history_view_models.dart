// Parte di budget_history_view.dart: modelli delle operazioni
// e dei dati dello storico.

part of 'budget_history_view.dart';

/// One operation returned by the `listBudgetHistory` Cloud Function.
class BudgetHistoryEvent {
  const BudgetHistoryEvent({
    required this.expenseId,
    required this.type,
    this.actorUid,
    this.counterpartUid,
    this.minorUnits,
    this.currency,
    this.reason,
    this.version,
    this.rate,
    this.at,
  });

  factory BudgetHistoryEvent.fromMap(Map<String, dynamic> map) {
    final at = map['at'];
    return BudgetHistoryEvent(
      expenseId: map['expenseId']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      actorUid: map['actorUid'] is String ? map['actorUid'] as String : null,
      counterpartUid: map['counterpartUid'] is String
          ? map['counterpartUid'] as String
          : null,
      minorUnits: map['minorUnits'] is int ? map['minorUnits'] as int : null,
      currency: map['currency'] is String ? map['currency'] as String : null,
      reason: map['reason'] is String ? map['reason'] as String : null,
      version: map['version'] is int ? map['version'] as int : null,
      rate: map['rate'] is num ? (map['rate'] as num).toDouble() : null,
      at: at is num ? DateTime.fromMillisecondsSinceEpoch(at.toInt()) : null,
    );
  }

  final String expenseId;
  final String type;
  final String? actorUid;
  final String? counterpartUid;
  final int? minorUnits;
  final String? currency;
  final String? reason;
  final int? version;
  final double? rate;
  final DateTime? at;
}

/// The data returned by `listBudgetHistory`, ready to display.
class BudgetHistoryData {
  const BudgetHistoryData({
    required this.events,
    required this.titles,
    required this.privateIds,
    required this.recordedNames,
  });

  factory BudgetHistoryData.fromResponse(Map<String, dynamic> response) {
    final events = response['events'] is List
        ? (response['events'] as List)
              .whereType<Map>()
              .map(
                (raw) =>
                    BudgetHistoryEvent.fromMap(Map<String, dynamic>.from(raw)),
              )
              .toList()
        : <BudgetHistoryEvent>[];
    final titles = <String, String>{};
    final privateIds = <String>{};
    final expenses = response['expenses'];
    if (expenses is Map) {
      for (final entry in expenses.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        titles['${entry.key}'] = value['title']?.toString() ?? '';
        if (value['visibility'] == 'private') privateIds.add('${entry.key}');
      }
    }
    final names = <String, String>{};
    final rawNames = response['names'];
    if (rawNames is Map) {
      for (final entry in rawNames.entries) {
        if (entry.value is String) names['${entry.key}'] = entry.value;
      }
    }
    return BudgetHistoryData(
      events: events,
      titles: titles,
      privateIds: privateIds,
      recordedNames: names,
    );
  }

  final List<BudgetHistoryEvent> events;
  final Map<String, String> titles;
  final Set<String> privateIds;
  final Map<String, String> recordedNames;
}
