// Parte di budget_create_dialog.dart: anteprima delle quote
// e conferma della spesa prima del salvataggio.

part of 'budget_create_dialog.dart';

extension _BudgetCreateDialogStatePreview on _BudgetCreateDialogState {
  Widget _expensePreview(bool it) {
    final color = AmaterasuColors.textPrimary;
    final muted = AmaterasuColors.textSecondary;

    try {
      final total = _totalMinor();

      final participants = _shared
          ? _selected.toList()
          : [widget.api.currentUid];

      Map<String, int>? custom;

      if (_shared && _customSplit) {
        custom = {
          for (final uid in participants)
            uid: BudgetMoneyInput.parse(
              _shareInputs[uid]?.text ?? '',
              _selectedCurrency,
              allowZero: true,
            ),
        };
      }

      final shares = BudgetExpenseSplitPreview.calculate(
        totalMinor: total,
        participants: participants,
        customShares: custom,
      );

      final paid = _status == 'planned'
          ? 0
          : _paymentAllocations.fold<int>(
              0,
              (sum, item) => sum + item.minorUnits,
            );

      if (paid > total) {
        return Text(
          budgetL10n(it).btCreatePaymentsExceedTotal,
          style: const TextStyle(color: AmaterasuColors.accentPeach),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            budgetL10n(it).btCreateSplitPreview,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AmaterasuSpacing.sm),
          Text(
            '${budgetL10n(it).btCreateRecordedBy}: ${_travelerName(widget.api.currentUid, it)}',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: AmaterasuSpacing.sm),
          for (final entry in shares.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _travelerName(entry.key, it),
                      style: TextStyle(color: color),
                    ),
                  ),
                  Text(
                    BudgetMoneyFormatter.format(entry.value, _selectedCurrency),
                    style: TextStyle(color: color),
                  ),
                ],
              ),
            ),
          const Divider(),
          Text(
            '${budgetL10n(it).btCreateTotal}: ${BudgetMoneyFormatter.format(total, _selectedCurrency)}',
            style: TextStyle(color: color),
          ),
          Text(
            '${budgetL10n(it).btCreateDeclaredPayments}: ${BudgetMoneyFormatter.format(paid, _selectedCurrency)}',
            style: TextStyle(color: muted),
          ),
          Text(
            '${budgetL10n(it).btCreateRemaining}: ${BudgetMoneyFormatter.format(total - paid, _selectedCurrency)}',
            style: TextStyle(color: muted),
          ),
        ],
      );
    } catch (_) {
      return Text(
        budgetL10n(it).btCreateCompleteTheAmountParticipants,
        style: TextStyle(color: muted),
      );
    }
  }

  Future<bool> _confirmExpense(bool it) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AmaterasuColors.surfaceCard,
        title: Text(
          budgetL10n(it).btCreateConfirmNewExpense,
          style: const TextStyle(color: AmaterasuColors.textPrimary),
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title.text.trim(),
                  style: const TextStyle(
                    color: AmaterasuColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: AmaterasuSpacing.sm),
                Text(
                  '${budgetL10n(it).btCategoryLabel}: $_category',
                  style: const TextStyle(color: AmaterasuColors.textSecondary),
                ),
                Text(
                  '${budgetL10n(it).btCreateType}: ${_shared ? (budgetL10n(it).btCreateShared) : (budgetL10n(it).btCreatePersonal)}',
                  style: const TextStyle(color: AmaterasuColors.textSecondary),
                ),
                Text(
                  '${budgetL10n(it).btStatusLabel}: $_status',
                  style: const TextStyle(color: AmaterasuColors.textSecondary),
                ),
                const SizedBox(height: AmaterasuSpacing.md),
                _expensePreview(it),
                const SizedBox(height: 14),
                Text(
                  budgetL10n(it).btCreatePaymentsRecordedInThis,
                  style: const TextStyle(
                    color: AmaterasuColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(budgetL10n(it).btCreateBackToEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(budgetL10n(it).btCreateConfirmAndSave),
          ),
        ],
      ),
    );

    return confirmed == true;
  }
}
