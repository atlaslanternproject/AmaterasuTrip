import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import '../calculations/budget_money_formatter.dart';
import 'budget_api.dart';
import 'budget_dialog_chrome.dart';
import 'budget_people.dart';

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

/// Sentence describing one operation, with names instead of internal IDs.
String budgetHistoryText(
  BudgetHistoryEvent event,
  AppLocalizations l10n,
  String Function(String? uid) nameOf,
) {
  final actor = nameOf(event.actorUid);
  final other = nameOf(event.counterpartUid);
  switch (event.type) {
    case 'created':
      return l10n.b86EvCreated(actor);
    case 'revised':
      return l10n.b86EvRevised(actor, '${event.version ?? '—'}');
    case 'reimbursementRequested':
      return l10n.b86EvRefundRequested(actor, other);
    case 'reimbursementConfirmed':
      return l10n.b86EvRefundConfirmed(actor, other);
    case 'reimbursementRejected':
      return l10n.b86EvRefundRejected(actor, other);
    case 'debtClosed':
      return l10n.b86EvDebtClosed(actor, other);
    case 'cancellationRequested':
      return l10n.b86EvCancelRequested(actor);
    case 'cancellationApproved':
      return l10n.b86EvCancelApproved(actor);
    case 'cancellationRejected':
      return l10n.b86EvCancelRejected(actor);
    case 'cancelled':
      return l10n.b86EvCancelled(actor);
    case 'rateChanged':
      return l10n.b86EvRateChanged(actor, '${event.rate ?? '—'}');
    default:
      return l10n.b86EvUnknown;
  }
}

IconData budgetHistoryIcon(String type) {
  switch (type) {
    case 'created':
      return Icons.add_circle_outline;
    case 'revised':
      return Icons.edit_outlined;
    case 'reimbursementRequested':
      return Icons.payments_outlined;
    case 'reimbursementConfirmed':
      return Icons.check_circle_outline;
    case 'reimbursementRejected':
    case 'cancellationRejected':
      return Icons.cancel_outlined;
    case 'debtClosed':
      return Icons.task_alt_outlined;
    case 'cancellationRequested':
    case 'cancellationApproved':
    case 'cancelled':
      return Icons.block_outlined;
    case 'rateChanged':
      return Icons.currency_exchange;
    default:
      return Icons.history;
  }
}

/// List of operations of one expense, or of the whole trip when
/// [expenseId] is null (B8.6). Data comes only from the Cloud Function,
/// which returns only what the current traveler may see.
class BudgetHistoryList extends StatefulWidget {
  const BudgetHistoryList({
    super.key,
    required this.api,
    this.expenseId,
    this.private = false,
    this.loader,
    this.liveNames,
  });

  final BudgetApi api;
  final String? expenseId;
  final bool private;

  /// Test hooks; default to the Cloud Function and the trip members.
  final Future<Map<String, dynamic>> Function()? loader;
  final Future<Map<String, String>>? liveNames;

  @override
  State<BudgetHistoryList> createState() => _BudgetHistoryListState();
}

class _BudgetHistoryListState extends State<BudgetHistoryList> {
  late final Future<(BudgetHistoryData, Map<String, String>)> _data = () async {
    final response =
        await (widget.loader?.call() ??
            widget.api.history(
              expenseId: widget.expenseId,
              private: widget.private,
            ));
    Map<String, String> live;
    try {
      live = await (widget.liveNames ?? widget.api.travelerNameMap);
    } catch (_) {
      live = const {};
    }
    return (BudgetHistoryData.fromResponse(response), live);
  }();

  String _money(BudgetHistoryEvent event) {
    final minor = event.minorUnits;
    final currency = event.currency;
    if (minor == null || currency == null) return '';
    try {
      return BudgetMoneyFormatter.format(minor, currency);
    } on ArgumentError {
      return '$minor $currency';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final local = MaterialLocalizations.of(context);
    return FutureBuilder<(BudgetHistoryData, Map<String, String>)>(
      future: _data,
      builder: (context, result) {
        if (result.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.b86HistoryError,
              style: const TextStyle(color: BudgetDialogChrome.muted),
            ),
          );
        }
        if (!result.hasData) return const LinearProgressIndicator();
        final (data, live) = result.data!;
        if (data.events.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.b86HistoryEmpty,
              style: const TextStyle(color: BudgetDialogChrome.muted),
            ),
          );
        }
        String nameOf(String? uid) => uid == null
            ? '—'
            : BudgetPeople.name(
                uid,
                live: live,
                recordedNames: data.recordedNames,
                fallback: l10n.b86FormerTraveler,
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final event in data.events)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  budgetHistoryIcon(event.type),
                  color: BudgetDialogChrome.gold,
                ),
                title: Text(
                  budgetHistoryText(event, l10n, nameOf),
                  style: const TextStyle(color: BudgetDialogChrome.cream),
                ),
                subtitle: Text(
                  [
                    if (widget.expenseId == null)
                      [
                        data.titles[event.expenseId] ?? '',
                        if (data.privateIds.contains(event.expenseId))
                          l10n.b86PrivateTag,
                      ].where((part) => part.isNotEmpty).join(' · '),
                    _money(event),
                    event.at == null
                        ? l10n.b86UnknownTime
                        : '${local.formatMediumDate(event.at!)} '
                              '${local.formatTimeOfDay(TimeOfDay.fromDateTime(event.at!))}',
                    if (event.reason != null) l10n.b86Reason(event.reason!),
                  ].where((part) => part.isNotEmpty).join('\n'),
                  style: const TextStyle(
                    color: BudgetDialogChrome.muted,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Trip-wide history (B8.6), opened from the expenses page.
class BudgetTripHistoryDialog extends StatelessWidget {
  const BudgetTripHistoryDialog({super.key, required this.api});

  final BudgetApi api;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: BudgetDialogChrome.background,
      shape: BudgetDialogChrome.shape,
      insetPadding: BudgetDialogChrome.insetPadding,
      titlePadding: BudgetDialogChrome.titlePadding,
      contentPadding: BudgetDialogChrome.contentPadding,
      actionsPadding: BudgetDialogChrome.actionsPadding,
      title: BudgetDialogChrome.header(
        title: l10n.b86TripHistory,
        subtitle: l10n.b86HistoryVisibility,
        icon: Icons.history,
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(child: BudgetHistoryList(api: api)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
