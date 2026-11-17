import 'budget_expense_day.dart';
import '../calculations/budget_money_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import '../data/budget_fx_service.dart';
import 'budget_api.dart';
import 'budget_category_picker.dart';
import 'budget_charts.dart';
import 'budget_expense_filters.dart';

/// B6: participant-scoped category totals. Shared and personal never mix.
/// All FX operations are presentation-only; original financial data is intact.
class BudgetCategoryDashboard extends StatefulWidget {
  const BudgetCategoryDashboard({
    super.key,
    required this.api,
    required this.mainCurrency,
    required this.displayCurrency,
    required this.filters,
    required this.onFiltersChanged,
  });

  final BudgetApi api;
  final String mainCurrency;
  final String displayCurrency;
  final BudgetExpenseFilters filters;
  final ValueChanged<BudgetExpenseFilters> onFiltersChanged;

  @override
  State<BudgetCategoryDashboard> createState() =>
      _BudgetCategoryDashboardState();
}

class _BudgetCategoryDashboardState extends State<BudgetCategoryDashboard> {
  static const _cream = Color(0xFFF2E7D5);
  static const _muted = Color(0xFFB7A99B);
  static const _gold = Color(0xFFE3A66C);
  static const _orange = Color(0xFFE17A43);
  static const _dark = Color(0xFF241A16);

  final BudgetFxService _fx = BudgetFxService();
  final Set<String> _pinsRequested = {};
  late Stream<QuerySnapshot<Map<String, dynamic>>> _shared;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _private;
  late Stream<Map<String, String>> _categories;

  bool _chartPersonal = false;

  String? _cachedFxKey;
  Future<Map<String, BudgetFxQuote?>>? _cachedFx;

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  void _loadStreams() {
    _shared = widget.api.sharedExpenses();
    _private = widget.api.privateExpenses();
    _categories = widget.api.budgetCategories();
  }

  @override
  void didUpdateWidget(covariant BudgetCategoryDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.api.tripId != widget.api.tripId) {
      _loadStreams();
      _cachedFxKey = null;
      _pinsRequested.clear();
    }
  }

  Map<String, dynamic> _map(dynamic raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

  String _money(int value, String currency) {
    return BudgetMoneyFormatter.format(value, currency);
  }

  DateTime? _createdAt(Map<String, dynamic> data) {
    return budgetExpenseDay(data);
  }

  Future<BudgetFxQuote?> _quoteFor(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String target,
  ) async {
    final data = doc.data();
    final source = _map(
      _map(data['snapshot'])['total'],
    )['currency']?.toString();
    if (source == null || source == target) {
      return null;
    }
    try {
      final locked = BudgetFxQuote.fromLocked(data['fxHistorical']);
      if (locked != null && locked.base == source && locked.quote == target) {
        return locked;
      }
      final created = _createdAt(data);
      if (created == null) {
        return null;
      }
      return await _fx.historical(source, target, created);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, BudgetFxQuote?>> _resolveQuotes(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String target,
  ) async {
    final entries = await Future.wait(
      docs.map((doc) async {
        return MapEntry(doc.id, await _quoteFor(doc, target));
      }),
    );
    return Map<String, BudgetFxQuote?>.fromEntries(entries);
  }

  Future<Map<String, BudgetFxQuote?>> _quoteFuture(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String target,
  ) {
    final key = [
      target,
      _chartPersonal.toString(),
      for (final doc in docs)
        '${doc.id}:${doc.data()['version']}:${doc.data()['fxHistorical']}',
    ].join('|');
    if (_cachedFxKey != key || _cachedFx == null) {
      _cachedFxKey = key;
      _cachedFx = _resolveQuotes(docs, target);
    }
    return _cachedFx!;
  }

  void _pinLegacyRates(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final relevant = docs
        .where((doc) {
          final data = doc.data();
          final currency = _map(_map(data['snapshot'])['total'])['currency'];
          return data['fxHistorical'] == null &&
              currency is String &&
              currency != widget.mainCurrency &&
              _createdAt(data) != null &&
              !_pinsRequested.contains('$_chartPersonal:${doc.id}');
        })
        .take(4)
        .toList();
    if (relevant.isEmpty) {
      return;
    }
    for (final doc in relevant) {
      _pinsRequested.add('$_chartPersonal:${doc.id}');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      for (final doc in relevant) {
        widget.api
            .ensureExpenseFx(expenseId: doc.id, private: _chartPersonal)
            .catchError((Object _) {
              // Historical display still works without pinning if provider is down.
            });
      }
    });
  }

  Widget _tab(String label, IconData icon, bool personal) {
    final chosen = _chartPersonal == personal;
    return Expanded(
      child: Material(
        color: chosen ? _orange : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _chartPersonal = personal),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: chosen ? _dark : _muted),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: chosen ? FontWeight.w700 : FontWeight.w500,
                      color: chosen ? _dark : _cream,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final it = Localizations.localeOf(context).languageCode == 'it';
    final target = widget.displayCurrency;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _shared,
      builder: (context, shared) {
        if (shared.hasError) {
          return Text(l10n.b6LoadingError);
        }
        if (!shared.hasData) {
          return const LinearProgressIndicator();
        }
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _private,
          builder: (context, personal) {
            if (personal.hasError) {
              return Text(l10n.b6LoadingError);
            }
            if (!personal.hasData) {
              return const LinearProgressIndicator();
            }
            return StreamBuilder<Map<String, String>>(
              stream: _categories,
              builder: (context, customResult) {
                final custom = customResult.data ?? const <String, String>{};
                final raw = _chartPersonal
                    ? personal.data!.docs
                    : shared.data!.docs;
                final docs = raw
                    .where(
                      (doc) =>
                          widget.filters.matches(doc.data(), DateTime.now()),
                    )
                    .toList();
                _pinLegacyRates(docs);
                return Card(
                  color: _dark,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF241A16),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF49312B)),
                          ),
                          child: Row(
                            children: [
                              _tab(l10n.b6Group, Icons.groups_outlined, false),
                              _tab(
                                l10n.b6Personal,
                                Icons.lock_outline_rounded,
                                true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _chartPersonal
                              ? l10n.b6PersonalByCategory
                              : l10n.b6GroupByCategory,
                          style: const TextStyle(
                            color: _cream,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          target,
                          style: const TextStyle(color: _gold, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<Map<String, BudgetFxQuote?>>(
                          future: _quoteFuture(docs, target),
                          builder: (context, rates) {
                            if (!rates.hasData) {
                              return const LinearProgressIndicator();
                            }
                            return _summary(
                              context,
                              docs,
                              target,
                              rates.data!,
                              custom,
                              l10n,
                              it,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _overviewMetric(String label, String value, {bool accent = false}) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF30231E),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF49352A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent ? _gold : _cream,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String target,
    Map<String, BudgetFxQuote?> quotes,
    Map<String, String> custom,
    AppLocalizations l10n,
    bool it,
  ) {
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
        excludedCount++;
        excluded[source] = (excluded[source] ?? 0) + amount;
        continue;
      }
      converted++;
      final members = _map(financial['shares']);
      people.addAll(members.keys);
      final own = _map(members[widget.api.currentUid]);
      if (own['currency'] == source && own['minorUnits'] is int) {
        final convertedOwn = BudgetFxService.convertMinor(
          own['minorUnits'] as int,
          source,
          target,
          fx,
        );
        if (convertedOwn != null) {
          myShare += convertedOwn;
        }
      }
      final expenseTime = _createdAt(data);
      if (expenseTime != null &&
          (mostRecentDate == null || expenseTime.isAfter(mostRecentDate))) {
        mostRecentDate = expenseTime;
        mostRecentTitle = data['title']?.toString() ?? '';
      }
      if (expenseTime != null) {
        final day = DateUtils.dateOnly(expenseTime);
        daily[day] = (daily[day] ?? 0) + value;
      }
      final category = data['category']?.toString() ?? 'other';
      totals[category] = (totals[category] ?? 0) + value;
      total += value;
      var advanceTotal = 0;
      for (final item in _map(financial['advances']).values) {
        final advance = _map(item);
        if (advance['currency'] == source && advance['minorUnits'] is int) {
          advanceTotal += advance['minorUnits'] as int;
        }
      }
      final ownAdvance = _map(
        _map(financial['advances'])[widget.api.currentUid],
      );
      if (ownAdvance['currency'] == source && ownAdvance['minorUnits'] is int) {
        myAdvances +=
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
        paid += convertedPaid;
      }
      if (fx != null) {
        observations['$source/$target'] =
            '${fx.source} ${fx.observedIso}${fx.manual ? ' · Manual' : ''}';
      }
    }
    final ordered = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final partial = excludedCount > 0;
    final trend = BudgetTrend.from(daily);
    String categoryLabel(String key) =>
        custom[key] ?? BudgetCategoryPicker.label(key, it);
    final hasExpenses = docs.isNotEmpty;
    final visiblePrimary = converted == 0 && hasExpenses
        ? '— $target'
        : _money(_chartPersonal ? total : myShare, target);
    final visiblePaid = converted == 0 && hasExpenses
        ? '—'
        : _money(paid, target);
    final visibleRemaining = converted == 0 && hasExpenses
        ? '—'
        : _money(total - paid, target);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF30231E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF49352A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _chartPersonal ? l10n.b6PersonalTotal : l10n.b6MyShare,
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                visiblePrimary,
                style: const TextStyle(
                  color: _cream,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (partial)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.b6PartialTotal,
                    style: const TextStyle(color: _gold, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                '${l10n.b6ExpenseCount}: ${docs.length}',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (!_chartPersonal && people.isNotEmpty)
              _overviewMetric(l10n.b6GroupTotal, _money(total, target)),
            _overviewMetric(
              _l10n(it).btDashMyAdvances,
              converted == 0 && hasExpenses
                  ? '— $target'
                  : _money(myAdvances, target),
            ),
            _overviewMetric(l10n.b6PaidToSuppliers, visiblePaid),
            _overviewMetric(
              l10n.b6OutstandingSuppliers,
              visibleRemaining,
              accent: true,
            ),
          ],
        ),
        if (mostRecentTitle != null && mostRecentTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '${l10n.b6LatestExpense}: $mostRecentTitle',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ),
        const Divider(height: 30),
        if (ordered.isEmpty)
          Text(l10n.b6NoExpenses, style: const TextStyle(color: _muted)),
        // B8.5: real charts built from the same converted totals.
        if (ordered.isNotEmpty && total > 0) ...[
          Text(
            l10n.b85CategoryChart,
            style: const TextStyle(color: _cream, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          BudgetCategoryChart(
            key: const Key('b85-category-chart'),
            values: [for (final entry in ordered) entry.value],
            labels: [for (final entry in ordered) categoryLabel(entry.key)],
            currency: target,
          ),
          const SizedBox(height: 14),
        ],
        for (final (index, entry) in ordered.indexed) ...[
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: BudgetChartPalette.at(index),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  categoryLabel(entry.key),
                  style: const TextStyle(
                    color: _cream,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _money(entry.value, target),
                style: const TextStyle(color: _gold),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total > 0 ? (entry.value / total).clamp(0.0, 1.0) : 0,
              minHeight: 8,
              backgroundColor: const Color(0xFF49312B),
              color: BudgetChartPalette.at(index),
            ),
          ),
          const SizedBox(height: 13),
        ],
        if (trend.points.isNotEmpty && total > 0) ...[
          const SizedBox(height: 10),
          Text(
            l10n.b85TrendChart,
            style: const TextStyle(color: _cream, fontWeight: FontWeight.w700),
          ),
          Text(
            trend.monthly ? l10n.b85TrendByMonth : l10n.b85TrendByDay,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          BudgetTrendChart(
            key: const Key('b85-trend-chart'),
            trend: trend,
            currency: target,
          ),
        ],
        if (partial && ordered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.b85ChartsExcludeMissingRates,
              style: const TextStyle(color: _gold, fontSize: 12),
            ),
          ),
        if (observations.isNotEmpty) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            collapsedIconColor: _gold,
            iconColor: _gold,
            title: Text(
              l10n.b6RateSource,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            children: [
              for (final entry in observations.entries)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                l10n.b6RateDoesNotChangeDebts,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ],
        if (excluded.isNotEmpty) ...[
          const Divider(height: 24),
          Text(
            l10n.b6MissingRate,
            style: const TextStyle(color: _gold, fontSize: 12),
          ),
          for (final entry in excluded.entries)
            Text(
              '${entry.key}: ${_money(entry.value, entry.key)}',
              style: const TextStyle(color: _gold, fontSize: 12),
            ),
          Text(
            '$excludedCount ${l10n.b6ExcludedCount}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

/// Texts of this screen, in the language chosen by the existing `it` flag.
AppLocalizations _l10n(bool it) =>
    lookupAppLocalizations(Locale(it ? 'it' : 'en'));
