// Parte di budget_user_settlement_summary.dart: ascolto dei dati
// e calcolo dei debiti da mostrare.

// ignore_for_file: invalid_use_of_protected_member
part of 'budget_user_settlement_summary.dart';

extension _BudgetUserSettlementSummaryStateData on _BudgetUserSettlementSummaryState {
  void _listen() {
    _expensesSub = widget.api.sharedExpenses().listen(
      (result) {
        if (!mounted) return;

        final current = <String>{};

        for (final doc in result.docs) {
          final data = doc.data();
          if (data['lifecycle'] == 'cancelled') continue;

          current.add(doc.id);
          _expenses[doc.id] = data;

          if (!_refundSubs.containsKey(doc.id)) {
            final id = doc.id;

            _refundSubs[id] = widget.api
                .reimbursements(id)
                .listen(
                  (refunds) {
                    if (!mounted) return;
                    setState(() {
                      _refunds[id] = refunds.docs
                          .map((item) => item.data())
                          .toList();
                      _loadedRefundIds.add(id);
                    });
                  },
                  onError: (Object error) {
                    if (!mounted) return;
                    setState(() => _error = error.toString());
                  },
                );
          }
        }

        for (final id in _expenses.keys.toList()) {
          if (!current.contains(id)) {
            _expenses.remove(id);
            _refunds.remove(id);
            _loadedRefundIds.remove(id);
            _refundSubs.remove(id)?.cancel();
          }
        }

        setState(() => _loading = false);
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      },
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  List<_DebtLine> _debts(Map<String, dynamic> snapshot) => [
    for (final debt in BudgetSnapshotDebts.allocate(snapshot))
      _DebtLine(debt.debtorUid, debt.creditorUid, debt.minorUnits),
  ];

  /// B8.6: current name, then the name recorded in the expenses,
  /// never an internal ID.
  String _person(String uid, Map<String, String> names) => BudgetPeople.name(
    uid,
    live: names,
    recordedNames: BudgetPeople.recordedAll(_expenses.values),
    fallback: AppLocalizations.of(context)!.b86FormerTraveler,
  );

  Widget _heading(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _BudgetUserSettlementSummaryState._cream,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
