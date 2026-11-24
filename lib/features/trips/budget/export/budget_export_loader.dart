// Legge una sola volta, quando si chiede l'esportazione, le spese condivise
// visibili all'utente, le sue spese personali e i rimborsi di ogni spesa
// condivisa. Nessun ascoltatore resta attivo.

import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import 'budget_export_model.dart';

Future<BudgetExport> loadBudgetExport(BudgetApi api) async {
  final names = await api.travelerNameMap;
  final shared = (await api.sharedExpenses().first).docs;
  final personal = (await api.privateExpenses().first).docs;
  final refunds = <String, List<Map<String, dynamic>>>{};
  for (final doc in shared) {
    final title = '${doc.data()['title'] ?? doc.id}';
    final list = (await api.reimbursements(doc.id).first).docs;
    if (list.isEmpty) continue;
    refunds.putIfAbsent(title, () => []).addAll(list.map((r) => r.data()));
  }
  return BudgetExport.fromDocs(
    shared: [for (final d in shared) d.data()],
    personal: [for (final d in personal) d.data()],
    refundsByTitle: refunds,
    nameOf: (uid) => names[uid] ?? uid,
  );
}
