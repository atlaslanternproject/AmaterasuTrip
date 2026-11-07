import '../calculations/budget_money_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import '../calculations/currency_minor_units.dart';
import '../data/budget_fx_service.dart';
import 'budget_api.dart';
import 'budget_category_picker.dart';
import 'budget_expense_filters.dart';
import 'budget_fx_manual_dialog.dart';
import '../../presentation/pages/create_trip/currency/trip_currency_picker_sheet.dart';
import '../../presentation/pages/create_trip/destination/services/destination_places_service.dart';

/// B6: participant-scoped category totals. Shared and personal never mix.
/// All FX operations are presentation-only; original financial data is intact.
class BudgetCategoryDashboard extends StatefulWidget {
  const BudgetCategoryDashboard({
    super.key,
    required this.api,
    required this.mainCurrency,
    required this.filters,
    required this.onFiltersChanged,
  });

  final BudgetApi api;
  final String mainCurrency;
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
  String? _targetCurrency;
  bool _chartPersonal = false;
  String _fxMode = 'historical';
  String? _cachedFxKey;
  Future<Map<String, BudgetFxQuote?>>? _cachedFx;

  @override
  void initState() {
    super.initState();
    _loadStreams();
    _restoreCurrency();
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
      _targetCurrency = null;
      _restoreCurrency();
    }
  }

  String get _preferenceKey =>
      'amaterasu.b6.summary.${widget.api.currentUid}.${widget.api.tripId}';

  Future<void> _restoreCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_preferenceKey);
      if (mounted && stored != null && BudgetFxService.validCurrency(stored)) {
        setState(() => _targetCurrency = stored);
      }
    } catch (_) {
      // A missing browser preference must never block the dashboard.
    }
  }

  Future<void> _setCurrency(String value) async {
    setState(() => _targetCurrency = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_preferenceKey, value);
    } catch (_) {
      // The in-memory selection is still usable.
    }
  }

  Future<void> _pickSummaryCurrency() async {
    final it = Localizations.localeOf(context).languageCode == 'it';
    final codes = CurrencyMinorUnits.supportedCodes.toSet();
    List<TripCurrency> currencies;

    try {
      final fetched = await const DestinationPlacesService().getCurrencies(
        languageCode: it ? 'it' : 'en',
      );

      currencies = fetched
          .where((item) => codes.contains(item.code.toUpperCase()))
          .toList();

      final found = currencies.map((item) => item.code.toUpperCase()).toSet();

      currencies.addAll(
        codes
            .difference(found)
            .map((code) => TripCurrency(code: code, name: code, symbol: code)),
      );
    } catch (_) {
      currencies = codes
          .map((code) => TripCurrency(code: code, name: code, symbol: code))
          .toList();
    }

    currencies.sort((a, b) => a.code.compareTo(b.code));

    if (!mounted) return;

    final chosen = await showModalBottomSheet<TripCurrency>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF231915),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: TripCurrencyPickerSheet(
          currencies: currencies,
          selectedCurrency: _targetCurrency ?? widget.mainCurrency,
          title: it ? 'Valuta di riepilogo' : 'Summary currency',
          searchHint: it ? 'Cerca una valuta' : 'Search currencies',
          noResultsText: it ? 'Nessuna valuta trovata' : 'No currencies found',
        ),
      ),
    );

    if (!mounted || chosen == null) return;

    await _setCurrency(chosen.code.toUpperCase());
  }

  Map<String, dynamic> _map(dynamic raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

  String _money(int value, String currency) {
    return BudgetMoneyFormatter.format(value, currency);
  }

  DateTime? _createdAt(Map<String, dynamic> data) {
    final value = data['createdAt'];
    return value is Timestamp ? value.toDate() : null;
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
      if (_fxMode == 'latest') {
        return await _fx.latest(source, target);
      }
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
      _fxMode,
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
    if (_fxMode != 'historical') {
      return;
    }
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

  Widget _filterDropdown({
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> changed,
  }) {
    return DropdownButton<String>(
      value: options.containsKey(value) ? value : options.keys.first,
      dropdownColor: _dark,
      underline: const SizedBox.shrink(),
      style: const TextStyle(color: _cream, fontSize: 13),
      items: [
        for (final entry in options.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: (next) {
        if (next != null) {
          changed(next);
        }
      },
    );
  }

  Widget _filters(
    Map<String, String> custom,
    bool it,
    AppLocalizations l10n,
    BudgetExpenseFilters current,
    ValueChanged<BudgetExpenseFilters> onChanged,
  ) {
    final categories = <String, String>{
      '': l10n.b6AllCategories,
      for (final id in const [
        'accommodation',
        'food',
        'transport',
        'activities',
        'shopping',
        'other',
      ])
        id: BudgetCategoryPicker.label(id, it),
      ...custom,
    };
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 4,
      children: [
        _filterDropdown(
          value: current.category,
          options: categories,
          changed: (category) =>
              onChanged(current.copyWith(category: category)),
        ),
        _filterDropdown(
          value: current.status,
          options: {
            '': l10n.b6AllStatuses,
            'planned': l10n.b6Planned,
            'outstanding': l10n.b6Outstanding,
            'paid': l10n.b6Paid,
          },
          changed: (status) => onChanged(current.copyWith(status: status)),
        ),
        _filterDropdown(
          value: current.days.toString(),
          options: {
            '0': l10n.b6AllPeriods,
            '30': l10n.b6Last30Days,
            '90': l10n.b6Last90Days,
          },
          changed: (days) => onChanged(current.copyWith(days: int.parse(days))),
        ),
        _filterDropdown(
          value: current.sort,
          options: {'newest': l10n.b6Newest, 'oldest': l10n.b6Oldest},
          changed: (sort) => onChanged(current.copyWith(sort: sort)),
        ),
      ],
    );
  }

  Future<void> _showFilterSheet(
    Map<String, String> custom,
    bool it,
    AppLocalizations l10n,
  ) async {
    var draft = widget.filters;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _dark,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: StatefulBuilder(
          builder: (sheetContext, updateSheet) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        it ? 'Filtri e ordinamento' : 'Filters and sorting',
                        style: const TextStyle(
                          color: _cream,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded, color: _cream),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _filters(
                  custom,
                  it,
                  l10n,
                  draft,
                  (value) => updateSheet(() => draft = value),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => updateSheet(
                        () => draft = const BudgetExpenseFilters(),
                      ),
                      icon: const Icon(
                        Icons.restart_alt_rounded,
                        color: _orange,
                      ),
                      label: Text(
                        it ? 'Ripristina' : 'Reset',
                        style: const TextStyle(color: _cream),
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        widget.onFiltersChanged(draft);
                        Navigator.pop(sheetContext);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: _dark,
                      ),
                      child: Text(it ? 'Applica' : 'Apply'),
                    ),
                  ],
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
    final target = _targetCurrency ?? widget.mainCurrency;
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => _showFilterSheet(custom, it, l10n),
                            icon: const Icon(
                              Icons.tune_rounded,
                              color: _orange,
                            ),
                            label: Text(
                              it
                                  ? 'Filtri e ordinamento'
                                  : 'Filters and sorting',
                              style: const TextStyle(color: _cream),
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 16,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              l10n.b6SummaryCurrency,
                              style: const TextStyle(color: _muted),
                            ),
                            OutlinedButton.icon(
                              onPressed: _pickSummaryCurrency,
                              icon: const Icon(
                                Icons.currency_exchange_rounded,
                                size: 18,
                                color: _orange,
                              ),
                              label: Text(
                                target,
                                style: const TextStyle(color: _cream),
                              ),
                            ),
                            _filterDropdown(
                              value: _fxMode,
                              options: {
                                'historical': l10n.b6Historical,
                                'latest': l10n.b6Latest,
                              },
                              changed: (next) => setState(() => _fxMode = next),
                            ),
                          ],
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
    final people = <String>{};
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
    final hasExpenses = docs.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          converted == 0 && hasExpenses
              ? '— $target'
              : _money(_chartPersonal ? total : myShare, target),
          style: const TextStyle(
            color: _cream,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _chartPersonal ? l10n.b6PersonalTotal : l10n.b6MyShare,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        if (partial)
          Text(
            l10n.b6PartialTotal,
            style: const TextStyle(color: _gold, fontSize: 12),
          ),
        const SizedBox(height: 10),
        Text(
          '${l10n.b6ExpenseCount}: ${docs.length}',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        if (!_chartPersonal && people.isNotEmpty) ...[
          Text(
            '${l10n.b6GroupTotal}: ${_money(total, target)}',
            style: const TextStyle(color: _cream),
          ),
          Text(
            '${l10n.b6AveragePerTraveler}: ${_money((total / people.length).round(), target)}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
        if (mostRecentTitle != null && mostRecentTitle.isNotEmpty)
          Text(
            '${l10n.b6LatestExpense}: $mostRecentTitle',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        const SizedBox(height: 10),
        Text(
          '${l10n.b6PaidToSuppliers}: ${converted == 0 && hasExpenses ? '—' : _money(paid, target)}',
          style: const TextStyle(color: _cream),
        ),
        Text(
          '${l10n.b6OutstandingSuppliers}: ${converted == 0 && hasExpenses ? '—' : _money(total - paid, target)}',
          style: const TextStyle(color: _gold),
        ),
        const Divider(height: 26),
        if (ordered.isEmpty)
          Text(l10n.b6NoExpenses, style: const TextStyle(color: _muted)),
        for (final entry in ordered) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  custom[entry.key] ??
                      BudgetCategoryPicker.label(entry.key, it),
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
              color: _orange,
            ),
          ),
          const SizedBox(height: 13),
        ],
        if (observations.isNotEmpty) ...[
          const Divider(height: 23),
          Text(
            l10n.b6RateSource,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          for (final entry in observations.entries)
            Text(
              '${entry.key}: ${entry.value}',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          Text(
            l10n.b6RateDoesNotChangeDebts,
            style: const TextStyle(color: _muted, fontSize: 12),
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
        if (_fxMode == 'historical' && target == widget.mainCurrency)
          for (final doc in docs)
            if (_canCorrect(doc))
              TextButton.icon(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => BudgetFxManualDialog(
                    api: widget.api,
                    expenseId: doc.id,
                    private: _chartPersonal,
                    from: _map(
                      _map(doc.data()['snapshot'])['total'],
                    )['currency'].toString(),
                    to: target,
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(
                  '${l10n.b6ManualRate}: ${doc.data()['title'] ?? ''}',
                ),
              ),
      ],
    );
  }

  bool _canCorrect(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final source = _map(_map(data['snapshot'])['total'])['currency'];
    return data['createdByUid'] == widget.api.currentUid &&
        source is String &&
        source != widget.mainCurrency;
  }
}
