// Parte di budget_reimbursements_panel.dart: nomi dei viaggiatori
// e calcolo dei debiti da mostrare.

part of 'budget_reimbursements_panel.dart';

extension _BudgetReimbursementsPanelStateData
    on _BudgetReimbursementsPanelState {
  Future<Map<String, String>> _loadNames() async {
    final travelers = await widget.api.travelers();
    final result = <String, String>{};

    for (final traveler in travelers) {
      final uid = traveler['uid']?.toString();
      final name = traveler['name']?.toString().trim();

      if (uid != null && name != null && name.isNotEmpty) {
        result[uid] = name;
      }
    }

    return result;
  }

  String _name(String uid, Map<String, String> names) => BudgetPeople.name(
    uid,
    live: names,
    expense: widget.expense,
    fallback: AppLocalizations.of(context)!.b86FormerTraveler,
  );

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  List<_DebtRow> _buildDebts(Map<String, dynamic> snapshot) =>
      BudgetSnapshotDebts.allocate(snapshot);

  int _sumStatus(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String debtorUid,
    String creditorUid,
    Set<String> statuses,
  ) => BudgetSnapshotDebts.sumFor(
    docs.map((doc) => doc.data()),
    debtorUid,
    creditorUid,
    statuses,
  );
}
