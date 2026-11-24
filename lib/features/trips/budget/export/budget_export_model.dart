// Dati dell'esportazione delle spese (solo lettura): spese condivise e
// personali, quote e pagamenti per persona, rimborsi e totali per valuta.
// Somma solo ciò che è già salvato: nessun calcolo del budget cambia.

class BudgetExportExpense {
  const BudgetExportExpense({
    required this.title,
    required this.category,
    required this.date,
    required this.status,
    required this.cancelled,
    required this.totalMinor,
    required this.currency,
    required this.paid,
    required this.shares,
    required this.personal,
    this.notes,
  });

  final String title;
  final String category;

  /// YYYY-MM-DD, or empty.
  final String date;

  /// planned, outstanding or paid.
  final String status;
  final bool cancelled;
  final int totalMinor;
  final String currency;

  /// Person name -> minor units.
  final Map<String, int> paid;
  final Map<String, int> shares;
  final bool personal;
  final String? notes;
}

class BudgetExportRefund {
  const BudgetExportRefund({
    required this.expense,
    required this.from,
    required this.to,
    required this.minor,
    required this.currency,
    required this.status,
  });

  final String expense;
  final String from;
  final String to;
  final int minor;
  final String currency;

  /// pending, confirmed, rejected or writtenOff.
  final String status;
}

class BudgetExport {
  const BudgetExport({required this.expenses, required this.refunds});

  final List<BudgetExportExpense> expenses;
  final List<BudgetExportRefund> refunds;

  Iterable<BudgetExportExpense> get _counted =>
      expenses.where((e) => !e.cancelled);

  /// Currency -> total of the expenses that are not cancelled.
  Map<String, int> get totals {
    final result = <String, int>{};
    for (final e in _counted) {
      result[e.currency] = (result[e.currency] ?? 0) + e.totalMinor;
    }
    return result;
  }

  /// (person, currency) -> share of the shared expenses.
  Map<(String, String), int> get sharesByPerson => _byPerson((e) => e.shares);

  /// (person, currency) -> amount paid for the shared expenses.
  Map<(String, String), int> get paidByPerson => _byPerson((e) => e.paid);

  Map<(String, String), int> _byPerson(
    Map<String, int> Function(BudgetExportExpense e) values,
  ) {
    final result = <(String, String), int>{};
    for (final e in _counted.where((e) => !e.personal)) {
      for (final entry in values(e).entries) {
        final key = (entry.key, e.currency);
        result[key] = (result[key] ?? 0) + entry.value;
      }
    }
    return result;
  }

  /// Builds the export from Firestore documents. [nameOf] turns a uid into
  /// the name shown (the expense's saved names are used first).
  static BudgetExport fromDocs({
    required List<Map<String, dynamic>> shared,
    required List<Map<String, dynamic>> personal,
    required Map<String, List<Map<String, dynamic>>> refundsByTitle,
    required String Function(String uid) nameOf,
  }) {
    BudgetExportExpense? read(Map<String, dynamic> data, bool isPersonal) {
      final snapshot = data['snapshot'];
      if (snapshot is! Map) return null;
      final total = snapshot['total'];
      if (total is! Map ||
          total['minorUnits'] is! int ||
          total['currency'] is! String) {
        return null;
      }
      final saved = data['participantNames'];
      String name(Object uid) =>
          saved is Map &&
              saved[uid] is String &&
              (saved[uid] as String).isNotEmpty
          ? saved[uid] as String
          : nameOf('$uid');
      Map<String, int> amounts(Object? raw) => {
        if (raw is Map)
          for (final entry in raw.entries)
            if (entry.value is Map && (entry.value as Map)['minorUnits'] is int)
              name(entry.key): (entry.value as Map)['minorUnits'] as int,
      };
      return BudgetExportExpense(
        title: '${data['title'] ?? ''}',
        category: '${data['category'] ?? 'other'}',
        date: data['expenseDate'] is String
            ? data['expenseDate'] as String
            : '',
        status: '${snapshot['status'] ?? ''}',
        cancelled: data['lifecycle'] == 'cancelled',
        totalMinor: total['minorUnits'] as int,
        currency: total['currency'] as String,
        paid: amounts(snapshot['advances']),
        shares: amounts(snapshot['shares']),
        personal: isPersonal,
        notes: data['notes'] is String && (data['notes'] as String).isNotEmpty
            ? data['notes'] as String
            : null,
      );
    }

    final expenses = [
      for (final data in shared) ?read(data, false),
      for (final data in personal) ?read(data, true),
    ]..sort((a, b) => a.date.compareTo(b.date));
    final refunds = [
      for (final entry in refundsByTitle.entries)
        for (final r in entry.value)
          if (r['minorUnits'] is int && r['currency'] is String)
            BudgetExportRefund(
              expense: entry.key,
              from: nameOf('${r['debtorUid'] ?? ''}'),
              to: nameOf('${r['creditorUid'] ?? ''}'),
              minor: r['minorUnits'] as int,
              currency: r['currency'] as String,
              status: '${r['status'] ?? ''}',
            ),
    ];
    return BudgetExport(expenses: expenses, refunds: refunds);
  }
}
