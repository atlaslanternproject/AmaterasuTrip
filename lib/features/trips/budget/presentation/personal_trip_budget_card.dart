import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../calculations/currency_minor_units.dart';
import '../calculations/personal_budget_spending_calculator.dart';
import '../data/budget_fx_service.dart';
import '../data/personal_trip_budget_repository.dart';
import '../models/personal_trip_budget.dart';
import 'budget_api.dart';
import 'budget_currency.dart';
import 'budget_money_input.dart';

class PersonalTripBudgetCard extends StatefulWidget {
  const PersonalTripBudgetCard({
    super.key,
    required this.api,
    required this.defaultCurrency,
  });

  final BudgetApi api;
  final String defaultCurrency;

  @override
  State<PersonalTripBudgetCard> createState() => _PersonalTripBudgetCardState();
}

class _SpendingResult {
  const _SpendingResult({required this.spent, required this.missing});

  final int spent;
  final int missing;
}

class _PersonalTripBudgetCardState extends State<PersonalTripBudgetCard> {
  static const _dark = Color(0xFF241A16);
  static const _cream = Color(0xFFF2E7D5);
  static const _muted = Color(0xFFB7A99B);
  static const _gold = Color(0xFFE3A66C);
  static const _orange = Color(0xFFE17A43);
  static const _red = Color(0xFFFF8A80);

  final _repository = PersonalTripBudgetRepository();
  final _fx = BudgetFxService();

  late Stream<PersonalTripBudget?> _budgetStream;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _sharedStream;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _privateStream;

  String? _cacheKey;
  Future<_SpendingResult>? _cacheFuture;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    _budgetStream = _repository.watch(widget.api.tripId);
    _sharedStream = widget.api.sharedExpenses();
    _privateStream = widget.api.privateExpenses();
    _cacheKey = null;
    _cacheFuture = null;
  }

  @override
  void didUpdateWidget(covariant PersonalTripBudgetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.api.tripId != widget.api.tripId) {
      _initialize();
    }
  }

  String _money(int value, String currency) {
    final factor = CurrencyMinorUnits.factor(currency);
    final digits = CurrencyMinorUnits.decimals(currency);
    final absolute = value.abs();
    final sign = value < 0 ? '-' : '';
    final whole = absolute ~/ factor;

    if (digits == 0) return '$sign$whole $currency';

    final decimal = (absolute % factor).toString().padLeft(digits, '0');
    return '$sign$whole,$decimal $currency';
  }

  String _editableAmount(PersonalTripBudget budget) {
    final factor = CurrencyMinorUnits.factor(budget.currency);
    final digits = CurrencyMinorUnits.decimals(budget.currency);
    final whole = budget.amountMinor ~/ factor;

    if (digits == 0) return '$whole';

    final decimal = (budget.amountMinor % factor).toString().padLeft(
      digits,
      '0',
    );
    return '$whole,$decimal';
  }

  Future<_SpendingResult> _compute(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> shared,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> personal,
    String targetCurrency,
  ) async {
    var spent = 0;
    var missing = 0;

    Future<void> addExpense(
      QueryDocumentSnapshot<Map<String, dynamic>> document,
      bool isPrivate,
    ) async {
      final data = document.data();

      if (!PersonalBudgetSpendingCalculator.isIncluded(data)) return;

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

      if (share.currency == targetCurrency) {
        spent += share.minorUnits;
        return;
      }

      try {
        BudgetFxQuote? quote;

        final locked = BudgetFxQuote.fromLocked(data['fxHistorical']);
        if (locked != null &&
            locked.base == share.currency &&
            locked.quote == targetCurrency) {
          quote = locked;
        } else {
          final created = data['createdAt'];
          if (created is Timestamp) {
            quote = await _fx.historical(
              share.currency,
              targetCurrency,
              created.toDate(),
            );
          }
        }

        final converted = BudgetFxService.convertMinor(
          share.minorUnits,
          share.currency,
          targetCurrency,
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
      await addExpense(document, false);
    }

    for (final document in personal) {
      await addExpense(document, true);
    }

    return _SpendingResult(spent: spent, missing: missing);
  }

  Future<_SpendingResult> _spending(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> shared,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> personal,
    String currency,
  ) {
    String fingerprint(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final data = doc.data();
      return '${doc.id}:${data['version']}:${data['lifecycle']}:'
          '${data['snapshot']}:${data['fxHistorical']}:${data['createdAt']}';
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

  Future<void> _edit(PersonalTripBudget? existing) async {
    final it = Localizations.localeOf(context).languageCode == 'it';
    final input = TextEditingController(
      text: existing == null ? '' : _editableAmount(existing),
    );
    var currency = existing?.currency ?? widget.defaultCurrency;
    var saving = false;
    String? error;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, update) => AlertDialog(
            backgroundColor: const Color(0xFF231915),
            title: Text(
              it ? 'Il mio budget' : 'My travel budget',
              style: const TextStyle(color: _cream),
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it
                          ? 'Questo importo è privato. Superarlo non '
                                'impedisce di registrare altre spese.'
                          : 'This amount is private. Exceeding it '
                                'never prevents recording more expenses.',
                      style: const TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: input,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: it ? 'Importo previsto' : 'Planned amount',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: currency,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: it ? 'Valuta' : 'Currency',
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final code in BudgetCurrency.supported)
                          DropdownMenuItem(value: code, child: Text(code)),
                      ],
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value == null) return;
                              update(() {
                                currency = value;
                                input.clear();
                                error = null;
                              });
                            },
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: _red)),
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
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              update(() {
                                saving = false;
                                error = '$e';
                              });
                            }
                          }
                        },
                  child: Text(it ? 'Rimuovi' : 'Remove'),
                ),
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: Text(it ? 'Annulla' : 'Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: const Color(0xFF100C0A),
                ),
                onPressed: saving
                    ? null
                    : () async {
                        update(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          final value = BudgetMoneyInput.parse(
                            input.text,
                            currency,
                          );
                          await _repository.save(
                            widget.api.tripId,
                            PersonalTripBudget(
                              amountMinor: value,
                              currency: currency,
                            ),
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            update(() {
                              saving = false;
                              error = '$e';
                            });
                          }
                        }
                      },
                child: Text(it ? 'Salva' : 'Save'),
              ),
            ],
          ),
        ),
      );
    } finally {
      input.dispose();
    }
  }

  Widget _panel(Widget content) => Card(
    color: _dark,
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(padding: const EdgeInsets.all(18), child: content),
  );

  @override
  Widget build(BuildContext context) {
    final it = Localizations.localeOf(context).languageCode == 'it';

    return StreamBuilder<PersonalTripBudget?>(
      stream: _budgetStream,
      builder: (context, state) {
        if (state.hasError) {
          return _panel(
            Text(
              it ? 'Errore nel caricamento del budget.' : 'Budget load error.',
              style: const TextStyle(color: _red),
            ),
          );
        }

        if (state.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        final budget = state.data;

        if (budget == null) {
          return _panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  it ? 'Il mio budget' : 'My travel budget',
                  style: const TextStyle(
                    color: _cream,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  it
                      ? 'Imposta un budget personale facoltativo, '
                            'visibile soltanto a te.'
                      : 'Set an optional personal travel budget, '
                            'visible only to you.',
                  style: const TextStyle(color: _muted),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _edit(null),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(it ? 'Imposta budget' : 'Set budget'),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _sharedStream,
          builder: (context, shared) {
            if (shared.hasError) {
              return _panel(
                Text(
                  it
                      ? 'Impossibile caricare le spese.'
                      : 'Unable to load expenses.',
                  style: const TextStyle(color: _red),
                ),
              );
            }
            if (!shared.hasData) {
              return const LinearProgressIndicator();
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _privateStream,
              builder: (context, personal) {
                if (personal.hasError) {
                  return _panel(
                    Text(
                      it
                          ? 'Impossibile caricare le spese personali.'
                          : 'Unable to load personal expenses.',
                      style: const TextStyle(color: _red),
                    ),
                  );
                }
                if (!personal.hasData) {
                  return const LinearProgressIndicator();
                }

                return FutureBuilder<_SpendingResult>(
                  future: _spending(
                    shared.data!.docs,
                    personal.data!.docs,
                    budget.currency,
                  ),
                  builder: (context, result) {
                    final spending = result.data;
                    final incomplete = spending == null || spending.missing > 0;
                    final remaining = spending == null
                        ? 0
                        : budget.remainingMinor(spending.spent);
                    final exceeded = !incomplete && remaining < 0;

                    return _panel(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                color: _gold,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  it ? 'Il mio budget' : 'My travel budget',
                                  style: const TextStyle(
                                    color: _cream,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: it ? 'Modifica budget' : 'Edit budget',
                                onPressed: () => _edit(budget),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: _gold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _money(budget.amountMinor, budget.currency),
                            style: const TextStyle(
                              color: _cream,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            it ? 'Budget previsto' : 'Planned budget',
                            style: const TextStyle(color: _muted),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            spending == null
                                ? '— ${budget.currency}'
                                : _money(spending.spent, budget.currency),
                            style: const TextStyle(
                              color: _cream,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            it
                                ? 'Spesa a tuo carico (pagata e da saldare)'
                                : 'Your share (paid and outstanding)',
                            style: const TextStyle(color: _muted),
                          ),
                          const SizedBox(height: 14),
                          if (incomplete)
                            Text(
                              it
                                  ? 'Rimanente non determinabile: '
                                        'alcuni importi o tassi non sono disponibili.'
                                  : 'Remaining amount unavailable: '
                                        'some amounts or exchange rates are missing.',
                              style: const TextStyle(color: _gold),
                            )
                          else ...[
                            Text(
                              exceeded
                                  ? (it ? 'Oltre il budget' : 'Over budget')
                                  : (it ? 'Disponibile' : 'Remaining'),
                              style: const TextStyle(color: _muted),
                            ),
                            Text(
                              _money(remaining.abs(), budget.currency),
                              style: TextStyle(
                                color: exceeded ? _red : _gold,
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: (spending.spent / budget.amountMinor)
                                    .clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: const Color(0xFF49312B),
                                color: exceeded ? _red : _orange,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            it
                                ? 'Le spese previste sono escluse. '
                                      'Il superamento non blocca nuove spese.'
                                : 'Planned expenses are excluded. '
                                      'Exceeding your budget never blocks expenses.',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
