// Lista delle operazioni di una spesa o dell'intero viaggio,
// letta dalla Cloud Function listBudgetHistory.

import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import '../calculations/budget_money_formatter.dart';
import 'budget_api.dart';
import 'budget_dialog_chrome.dart';
import 'budget_people.dart';

part 'budget_history_view_models.dart';
part 'budget_history_view_texts.dart';
part 'budget_history_view_trip_dialog.dart';

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

  // TODO(audit): C8 _money ripetuto in 3 file con gestione errori diversa: decidere una sola regola.
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
