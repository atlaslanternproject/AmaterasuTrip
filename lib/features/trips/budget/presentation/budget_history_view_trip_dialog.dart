// Parte di budget_history_view.dart: dialogo con lo storico
// di tutto il viaggio.

part of 'budget_history_view.dart';

/// Trip-wide history (B8.6), opened from the expenses page.
class BudgetTripHistoryDialog extends StatelessWidget {
  const BudgetTripHistoryDialog({super.key, required this.api});

  final BudgetApi api;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: BudgetDialogChrome.background,
      shape: BudgetDialogChrome.shape,
      insetPadding: BudgetDialogChrome.insetPadding,
      titlePadding: BudgetDialogChrome.titlePadding,
      contentPadding: BudgetDialogChrome.contentPadding,
      actionsPadding: BudgetDialogChrome.actionsPadding,
      title: BudgetDialogChrome.header(
        title: l10n.b86TripHistory,
        subtitle: l10n.b86HistoryVisibility,
        icon: Icons.history,
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(child: BudgetHistoryList(api: api)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
