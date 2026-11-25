// Totali delle spese per categoria e per persona nella valuta scelta,
// estratti senza cambiamenti dal cruscotto delle categorie (tappa 3b):
// stesso tasso per spesa (bloccato sulla spesa, altrimenti storico del
// giorno), stessa conversione, stesse esclusioni. Usati dal cruscotto e
// dalle Statistiche; nessuna scrittura.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/budget_fx_service.dart';
import 'budget_expense_day.dart';

Map<String, dynamic> _map(dynamic raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

/// Rate of one expense towards [target]: the locked one when it matches,
/// otherwise the historical rate of the expense day; null when the same
/// currency or not available.
Future<BudgetFxQuote?> budgetCategoryQuoteFor(
  Map<String, dynamic> data,
  String target,
  BudgetFxService fx,
) async {
  final source = _map(_map(data['snapshot'])['total'])['currency']?.toString();
  if (source == null || source == target) {
    return null;
  }
  try {
    final locked = BudgetFxQuote.fromLocked(data['fxHistorical']);
    if (locked != null && locked.base == source && locked.quote == target) {
      return locked;
    }
    final created = budgetExpenseDay(data);
    if (created == null) {
      return null;
    }
    return await fx.historical(source, target, created);
  } catch (_) {
    return null;
  }
}

/// Rates of [docs] by expense ID.
Future<Map<String, BudgetFxQuote?>> budgetCategoryQuotes(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  String target,
  BudgetFxService fx,
) async {
  final entries = await Future.wait(
    docs.map((doc) async {
      return MapEntry(
        doc.id,
        await budgetCategoryQuoteFor(doc.data(), target, fx),
      );
    }),
  );
  return Map<String, BudgetFxQuote?>.fromEntries(entries);
}

/// Totals of a list of expenses in [target] (minor units).
class BudgetCategoryTotals {
  BudgetCategoryTotals._();

  final totals = <String, int>{};
  final excluded = <String, int>{};
  final observations = <String, String>{};
  var total = 0;
  var paid = 0;
  var converted = 0;
  var excludedCount = 0;
  var myShare = 0;
  var myAdvances = 0;
  final people = <String>{};
  final daily = <DateTime, int>{};
  String? mostRecentTitle;
  DateTime? mostRecentDate;

  /// Share of each person, converted like [myShare] (same rule).
  final perPerson = <String, int>{};

  static BudgetCategoryTotals compute(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String target,
    Map<String, BudgetFxQuote?> quotes,
    String? currentUid,
  ) {
    final r = BudgetCategoryTotals._();
    for (final doc in docs) {
      final data = doc.data();
      final financial = _map(data['snapshot']);
      final amountMap = _map(financial['total']);
      final source = amountMap['currency']?.toString();
      final amount = amountMap['minorUnits'];
      if (source == null ||
          !BudgetFxService.validCurrency(source) ||
          amount is! int ||
          amount < 0) {
        continue;
      }
      final fx = quotes[doc.id];
      final value = BudgetFxService.convertMinor(amount, source, target, fx);
      if (value == null) {
        r.excludedCount++;
        r.excluded[source] = (r.excluded[source] ?? 0) + amount;
        continue;
      }
      r.converted++;
      final members = _map(financial['shares']);
      r.people.addAll(members.keys);
      for (final entry in members.entries) {
        final share = _map(entry.value);
        if (share['currency'] == source && share['minorUnits'] is int) {
          final convertedShare = BudgetFxService.convertMinor(
            share['minorUnits'] as int,
            source,
            target,
            fx,
          );
          if (convertedShare != null) {
            r.perPerson[entry.key] =
                (r.perPerson[entry.key] ?? 0) + convertedShare;
            if (entry.key == currentUid) {
              r.myShare += convertedShare;
            }
          }
        }
      }
      final expenseTime = budgetExpenseDay(data);
      if (expenseTime != null &&
          (r.mostRecentDate == null ||
              expenseTime.isAfter(r.mostRecentDate!))) {
        r.mostRecentDate = expenseTime;
        r.mostRecentTitle = data['title']?.toString() ?? '';
      }
      if (expenseTime != null) {
        final day = DateUtils.dateOnly(expenseTime);
        r.daily[day] = (r.daily[day] ?? 0) + value;
      }
      final category = data['category']?.toString() ?? 'other';
      r.totals[category] = (r.totals[category] ?? 0) + value;
      r.total += value;
      var advanceTotal = 0;
      for (final item in _map(financial['advances']).values) {
        final advance = _map(item);
        if (advance['currency'] == source && advance['minorUnits'] is int) {
          advanceTotal += advance['minorUnits'] as int;
        }
      }
      final ownAdvance = _map(_map(financial['advances'])[currentUid]);
      if (ownAdvance['currency'] == source && ownAdvance['minorUnits'] is int) {
        r.myAdvances +=
            BudgetFxService.convertMinor(
              ownAdvance['minorUnits'] as int,
              source,
              target,
              fx,
            ) ??
            0;
      }
      final convertedPaid = BudgetFxService.convertMinor(
        advanceTotal,
        source,
        target,
        fx,
      );
      if (convertedPaid != null) {
        r.paid += convertedPaid;
      }
      if (fx != null) {
        r.observations['$source/$target'] =
            '${fx.source} ${fx.observedIso}${fx.manual ? ' · Manual' : ''}';
      }
    }
    return r;
  }
}
