part of 'budget_category_dashboard.dart';

extension _BudgetCategoryDashboardStateRates on _BudgetCategoryDashboardState {
  void _loadStreams() {
    _shared = widget.api.sharedExpenses();
    _private = widget.api.privateExpenses();
    _categories = widget.api.budgetCategories();
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
}
