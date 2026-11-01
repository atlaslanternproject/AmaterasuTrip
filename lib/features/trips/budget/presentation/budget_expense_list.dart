import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'budget_api.dart';
import 'budget_expense_details_dialog.dart';

class BudgetExpenseList extends StatelessWidget {
  const BudgetExpenseList({
    super.key,
    required this.api,
    required this.private,
  });

  final BudgetApi api;
  final bool private;

  @override
  Widget build(BuildContext context) {
    final it = Localizations.localeOf(context).languageCode == 'it';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: private ? api.privateExpenses() : api.sharedExpenses(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${it ? "Errore caricamento" : "Loading error"}: '
              '${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              it ? 'Ancora nessuna spesa.' : 'No expenses yet.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            if (data['lifecycle'] == 'cancelled') {
              return const SizedBox.shrink();
            }
            final raw = data['snapshot'];
            if (raw is! Map) return const SizedBox.shrink();

            final financial = Map<String, dynamic>.from(raw);
            final total = Map<String, dynamic>.from(financial['total'] as Map);
            final units = total['minorUnits'] as int? ?? 0;
            final currency = total['currency'] as String? ?? 'EUR';
            final status = financial['status']?.toString() ?? '';
            final title =
                (data['title'] is String &&
                    (data['title'] as String).trim().isNotEmpty)
                ? data['title'] as String
                : (it ? 'Spesa senza titolo' : 'Untitled expense');
            final category = data['category']?.toString() ?? 'other';
            final notes = data['notes']?.toString() ?? '';

            final digits = switch (currency) {
              'JPY' || 'KRW' || 'VND' => 0,
              'KWD' || 'BHD' || 'OMR' || 'JOD' || 'TND' => 3,
              _ => 2,
            };
            final factor = digits == 0 ? 1 : (digits == 3 ? 1000 : 100);
            final amount = (units / factor).toStringAsFixed(digits);

            final shares = financial['shares'] is Map
                ? Map<String, dynamic>.from(financial['shares'] as Map)
                : <String, dynamic>{};
            final advances = financial['advances'] is Map
                ? Map<String, dynamic>.from(financial['advances'] as Map)
                : <String, dynamic>{};

            return Card(
              color: const Color(0xFF241A16),
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => BudgetExpenseDetailsDialog(
                    expense: data,
                    expenseId: doc.id,
                    api: api,
                    isPrivate: private,
                  ),
                ),
                contentPadding: const EdgeInsets.all(14),
                leading: Icon(
                  private ? Icons.lock_outline : Icons.receipt_long_outlined,
                  color: const Color(0xFFE3A66C),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF2E7D5),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  '$amount $currency · $category · '
                  '${it ? "Stato" : "Status"}: $status · '
                  '${it ? "Quote" : "Shares"}: ${shares.length} · '
                  '${it ? "Anticipanti" : "Payers"}: ${advances.length}',
                  style: const TextStyle(color: Color(0xFFB7A99B)),
                ),
                isThreeLine: notes.isNotEmpty,
                trailing: notes.isEmpty
                    ? Text(
                        'v${data['version'] ?? 1}',
                        style: const TextStyle(color: Color(0xFFB7A99B)),
                      )
                    : Tooltip(
                        message: notes,
                        child: const Icon(
                          Icons.notes_outlined,
                          color: Color(0xFFE3A66C),
                        ),
                      ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
