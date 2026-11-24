// Pulsante "Esporta spese" della pagina spese: sceglie CSV (per Excel) o
// PDF (pagina da stampare o salvare come PDF), legge i dati una volta e
// scarica il file. Solo lettura: nessun dato del budget cambia.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/files/amaterasu_files.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/export/budget_export_loader.dart';
import 'package:amaterasutrip/features/trips/budget/export/budget_export_model.dart';
import 'package:amaterasutrip/features/trips/budget/export/budget_export_writer.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_category_picker.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripExpensesExportButton extends StatelessWidget {
  const TripExpensesExportButton({
    super.key,
    required this.api,
    this.load = loadBudgetExport,
    this.download = amaterasuDownloadText,
    this.print = amaterasuPrintHtml,
  });

  final BudgetApi api;
  final Future<BudgetExport> Function(BudgetApi api) load;
  final bool Function(String name, String mime, String text) download;
  final bool Function(String html) print;

  static BudgetExportTexts texts(AppLocalizations l10n, bool it) =>
      BudgetExportTexts(
        title: l10n.budgetExportTitle,
        expensesHeader: l10n.budgetExportExpenseColumns.split('|'),
        refundsHeader: l10n.budgetExportRefundColumns.split('|'),
        totalsHeader: l10n.budgetExportTotalColumns.split('|'),
        personsHeader: l10n.budgetExportPersonColumns.split('|'),
        decimalComma: it,
        label: (code) => switch (code) {
          'planned' => l10n.budgetExportPlanned,
          'outstanding' => l10n.budgetExportOutstanding,
          'paid' => l10n.budgetExportPaid,
          'cancelled' => l10n.budgetExportCancelled,
          'personal' => l10n.budgetExportPersonal,
          'shared' => l10n.budgetExportShared,
          'pending' => l10n.budgetExportPending,
          'confirmed' => l10n.budgetExportConfirmed,
          'rejected' => l10n.budgetExportRejected,
          'writtenOff' => l10n.budgetExportWrittenOff,
          _ => BudgetCategoryPicker.label(code, it),
        },
      );

  Future<void> _export(BuildContext context, bool pdf) async {
    final l10n = AppLocalizations.of(context)!;
    final it = Localizations.localeOf(context).languageCode == 'it';
    final messenger = ScaffoldMessenger.of(context);
    try {
      final writer = BudgetExportWriter(await load(api), texts(l10n, it));
      final ok = pdf
          ? print(writer.html())
          : download('spese.csv', 'text/csv;charset=utf-8', writer.csv());
      if (!ok) throw StateError('not available');
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.budgetExportError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<bool>(
      key: const Key('expenses-export'),
      tooltip: l10n.budgetExportTitle,
      color: AmaterasuColors.surfaceCard,
      icon: const Icon(
        Icons.ios_share_rounded,
        color: AmaterasuColors.textPrimary,
      ),
      onSelected: (pdf) => _export(context, pdf),
      itemBuilder: (_) => [
        PopupMenuItem(
          key: const Key('expenses-export-csv'),
          value: false,
          child: Text(l10n.budgetExportCsv),
        ),
        PopupMenuItem(
          key: const Key('expenses-export-pdf'),
          value: true,
          child: Text(l10n.budgetExportPdf),
        ),
      ],
    );
  }
}
