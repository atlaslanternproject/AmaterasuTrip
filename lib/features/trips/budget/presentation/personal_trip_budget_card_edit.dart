// Parte di personal_trip_budget_card.dart: dialogo per impostare
// o rimuovere il budget personale.

part of 'personal_trip_budget_card.dart';

extension _PersonalTripBudgetCardStateEdit on _PersonalTripBudgetCardState {
  Future<void> _edit(PersonalTripBudget? existing) async {
    final it = Localizations.localeOf(context).languageCode == 'it';

    final input = TextEditingController(
      text: existing == null ? '' : _editableAmount(existing),
    );

    String currency = existing?.currency ?? widget.defaultCurrency;
    bool saving = false;
    String? error;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, update) => AlertDialog(
            backgroundColor: AmaterasuColors.surfaceCard,
            title: Text(
              budgetL10n(it).btPersonalMyTravelBudget,
              style: const TextStyle(
                color: _PersonalTripBudgetCardState._cream,
              ),
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budgetL10n(it).btPersonalOnlyYouCanSee,
                      style: const TextStyle(
                        color: _PersonalTripBudgetCardState._muted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: input,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: budgetL10n(it).btPersonalPlannedAmount,
                        suffixText: currency,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: saving
                            ? null
                            : () async {
                                final chosen = await _pickCurrency(
                                  dialogContext,
                                  currency,
                                );

                                if (chosen == null ||
                                    !dialogContext.mounted ||
                                    chosen == currency) {
                                  return;
                                }

                                update(() {
                                  currency = chosen;
                                  input.clear();
                                  error = null;
                                });
                              },
                        icon: const Icon(Icons.currency_exchange_rounded),
                        label: Text(
                          '${budgetL10n(it).btCurrencyLabel}: $currency',
                        ),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: _PersonalTripBudgetCardState._red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              if (existing != null)
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          update(() {
                            saving = true;
                            error = null;
                          });

                          try {
                            await _repository.remove(widget.api.tripId);

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              update(() {
                                saving = false;
                                error = _friendlyError(e, it);
                              });
                            }
                          }
                        },
                  child: Text(budgetL10n(it).btActionRemove),
                ),
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(budgetL10n(it).btActionCancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _PersonalTripBudgetCardState._orange,
                  foregroundColor: AmaterasuColors.surfaceDeep,
                ),
                onPressed: saving
                    ? null
                    : () async {
                        update(() {
                          saving = true;
                          error = null;
                        });

                        try {
                          final amountMinor = BudgetMoneyInput.parse(
                            input.text,
                            currency,
                          );

                          final budget = PersonalTripBudget(
                            amountMinor: amountMinor,
                            currency: currency,
                          );

                          if (!budget.isValid) {
                            throw ArgumentError('Invalid personal budget.');
                          }

                          await _repository.save(widget.api.tripId, budget);

                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            update(() {
                              saving = false;
                              error = _friendlyError(e, it);
                            });
                          }
                        }
                      },
                child: Text(budgetL10n(it).btPersonalSave),
              ),
            ],
          ),
        ),
      );
    } finally {
      input.dispose();
    }
  }
}
