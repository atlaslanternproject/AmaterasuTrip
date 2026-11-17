// Parte di personal_trip_budget_card.dart: calcolo di quanto
// è stato speso rispetto al budget.

part of 'personal_trip_budget_card.dart';

class _SpendingResult {
  const _SpendingResult({required this.spent, required this.missing});

  final int spent;
  final int missing;
}

extension _PersonalTripBudgetCardStateSpending on _PersonalTripBudgetCardState {
  void _initialize() {
    _budgetStream = _repository.watch(widget.api.tripId);
    _sharedStream = widget.api.sharedExpenses();
    _privateStream = widget.api.privateExpenses();

    _cacheKey = null;
    _cacheFuture = null;
  }

  Future<_SpendingResult> _compute(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> shared,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> personal,
    String target,
  ) async {
    int spent = 0;
    int missing = 0;

    Future<void> add(
      QueryDocumentSnapshot<Map<String, dynamic>> document,
      bool isPrivate,
    ) async {
      final data = document.data();

      if (!PersonalBudgetSpendingCalculator.isIncluded(data)) {
        return;
      }

      final share = PersonalBudgetSpendingCalculator.ownShare(
        data,
        uid: widget.api.currentUid,
        privateExpense: isPrivate,
      );

      if (share == null || !BudgetFxService.validCurrency(share.currency)) {
        missing++;
        return;
      }

      if (share.minorUnits == 0) return;

      if (share.currency == target) {
        spent += share.minorUnits;
        return;
      }

      try {
        BudgetFxQuote? quote;

        final locked = BudgetFxQuote.fromLocked(data['fxHistorical']);

        if (locked != null &&
            locked.base == share.currency &&
            locked.quote == target) {
          quote = locked;
        } else {
          final createdAt = budgetExpenseDay(data);

          if (createdAt != null) {
            quote = await _fx.historical(share.currency, target, createdAt);
          }
        }

        final converted = BudgetFxService.convertMinor(
          share.minorUnits,
          share.currency,
          target,
          quote,
        );

        if (converted == null) {
          missing++;
        } else {
          spent += converted;
        }
      } catch (_) {
        missing++;
      }
    }

    for (final document in shared) {
      await add(document, false);
    }

    for (final document in personal) {
      await add(document, true);
    }

    return _SpendingResult(spent: spent, missing: missing);
  }

  Future<_SpendingResult> _spending(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> shared,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> personal,
    String currency,
  ) {
    String fingerprint(QueryDocumentSnapshot<Map<String, dynamic>> document) {
      final data = document.data();

      return '${document.id}:${data['version']}:'
          '${data['lifecycle']}:${data['snapshot']}:'
          '${data['fxHistorical']}:${budgetExpenseDay(data)}';
    }

    final key = [
      widget.api.tripId,
      widget.api.currentUid,
      currency,
      ...shared.map((doc) => 'S:${fingerprint(doc)}'),
      ...personal.map((doc) => 'P:${fingerprint(doc)}'),
    ].join('|');

    if (key != _cacheKey || _cacheFuture == null) {
      _cacheKey = key;
      _cacheFuture = _compute(shared, personal, currency);
    }

    return _cacheFuture!;
  }

  Widget _panel(Widget content) {
    return Card(
      color: _PersonalTripBudgetCardState._background,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(18), child: content),
    );
  }
}
