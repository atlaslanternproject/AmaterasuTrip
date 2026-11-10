import 'budget_expense_day.dart';
import '../calculations/budget_money_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../calculations/personal_budget_spending_calculator.dart';
import '../data/budget_fx_service.dart';
import '../data/personal_trip_budget_repository.dart';
import '../models/personal_trip_budget.dart';
import '../../presentation/pages/create_trip/currency/trip_currency_picker_sheet.dart';
import '../../presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'budget_api.dart';
import 'budget_currency.dart';
import 'budget_money_input.dart';
import 'budget_display_amount.dart';

class PersonalTripBudgetCard extends StatefulWidget {
  const PersonalTripBudgetCard({
    super.key,
    required this.api,
    required this.defaultCurrency,
    required this.displayCurrency,
    this.repository,
  });

  final BudgetApi api;
  final String defaultCurrency;
  final String displayCurrency;

  /// Defaults to the Firestore repository; replaceable in tests.
  final PersonalTripBudgetRepository? repository;

  @override
  State<PersonalTripBudgetCard> createState() => _PersonalTripBudgetCardState();
}

class _SpendingResult {
  const _SpendingResult({required this.spent, required this.missing});

  final int spent;
  final int missing;
}

class _PersonalTripBudgetCardState extends State<PersonalTripBudgetCard> {
  static const _background = Color(0xFF241A16);
  static const _cream = Color(0xFFF2E7D5);
  static const _muted = Color(0xFFB7A99B);
  static const _gold = Color(0xFFE3A66C);
  static const _orange = Color(0xFFE17A43);
  static const _red = Color(0xFFFF8A80);

  late final PersonalTripBudgetRepository _repository =
      widget.repository ?? widget.api.personalBudgetRepository;

  final BudgetFxService _fx = BudgetFxService();

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

  String _editableAmount(PersonalTripBudget budget) {
    return BudgetMoneyFormatter.format(
      budget.amountMinor,
      budget.currency,
      includeCurrency: false,
    );
  }

  Future<String?> _pickCurrency(
    BuildContext dialogContext,
    String selected,
  ) async {
    final it = Localizations.localeOf(context).languageCode == 'it';
    final supported = BudgetCurrency.supported.toSet();

    List<TripCurrency> currencies;

    try {
      final fetched = await const DestinationPlacesService().getCurrencies(
        languageCode: it ? 'it' : 'en',
      );

      currencies = fetched
          .where((item) => supported.contains(item.code.toUpperCase()))
          .toList();

      final found = currencies.map((item) => item.code.toUpperCase()).toSet();

      currencies.addAll(
        supported
            .difference(found)
            .map((code) => TripCurrency(code: code, name: code, symbol: code)),
      );
    } catch (_) {
      currencies = supported
          .map((code) => TripCurrency(code: code, name: code, symbol: code))
          .toList();
    }

    currencies.sort((a, b) => a.code.compareTo(b.code));

    if (!dialogContext.mounted) return null;

    final chosen = await showModalBottomSheet<TripCurrency>(
      context: dialogContext,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF231915),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: TripCurrencyPickerSheet(
          currencies: currencies,
          selectedCurrency: selected,
          title: it ? 'Valuta del budget' : 'Budget currency',
          searchHint: it ? 'Cerca una valuta' : 'Search currencies',
          noResultsText: it ? 'Nessuna valuta trovata' : 'No currencies found',
        ),
      ),
    );

    if (chosen == null) return null;

    return BudgetCurrency.normalize(chosen.code);
  }

  String _friendlyError(Object error, bool it) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return it
          ? 'Firestore ha negato il salvataggio. '
                'Le regole B7 devono essere presenti nel '
                'progetto Firebase utilizzato.'
          : 'Firestore denied the write. '
                'B7 rules must be deployed to the '
                'Firebase project in use.';
    }

    if (error is ArgumentError || error is FormatException) {
      return it
          ? 'Importo o valuta non validi.'
          : 'Invalid amount or currency.';
    }

    return it ? 'Operazione non riuscita: $error' : 'Operation failed: $error';
  }

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
                          ? 'Solo tu puoi vedere questo budget. '
                                'Superarlo non blocca nuove spese.'
                          : 'Only you can see this budget. '
                                'Exceeding it never blocks new expenses.',
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
                        label: Text('${it ? 'Valuta' : 'Currency'}: $currency'),
                      ),
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
                  child: Text(it ? 'Rimuovi' : 'Remove'),
                ),
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
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

  Future<_SpendingResult> _compute(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> shared,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> personal,
    String target,
  ) async {
    int spent = 0;
    int missing = 0;

    Future<void> add(
      QueryDocumentSnapshot<Map<String, dynamic>> document,
      bool isPrivate,
    ) async {
      final data = document.data();

      if (!PersonalBudgetSpendingCalculator.isIncluded(data)) {
        return;
      }

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

      if (share.currency == target) {
        spent += share.minorUnits;
        return;
      }

      try {
        BudgetFxQuote? quote;

        final locked = BudgetFxQuote.fromLocked(data['fxHistorical']);

        if (locked != null &&
            locked.base == share.currency &&
            locked.quote == target) {
          quote = locked;
        } else {
          final createdAt = budgetExpenseDay(data);

          if (createdAt != null) {
            quote = await _fx.historical(share.currency, target, createdAt);
          }
        }

        final converted = BudgetFxService.convertMinor(
          share.minorUnits,
          share.currency,
          target,
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
      await add(document, false);
    }

    for (final document in personal) {
      await add(document, true);
    }

    return _SpendingResult(spent: spent, missing: missing);
  }

  Future<_SpendingResult> _spending(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> shared,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> personal,
    String currency,
  ) {
    String fingerprint(QueryDocumentSnapshot<Map<String, dynamic>> document) {
      final data = document.data();

      return '${document.id}:${data['version']}:'
          '${data['lifecycle']}:${data['snapshot']}:'
          '${data['fxHistorical']}:${budgetExpenseDay(data)}';
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

  Widget _panel(Widget content) {
    return Card(
      color: _background,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(18), child: content),
    );
  }

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
                      : 'Set an optional personal budget '
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

                    final incomplete =
                        spending == null ||
                        spending.missing > 0 ||
                        result.hasError;

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
                          BudgetDisplayAmount(
                            minorUnits: budget.amountMinor,
                            originalCurrency: budget.currency,
                            displayCurrency: widget.displayCurrency,
                            fontSize: 26,
                          ),
                          Text(
                            it ? 'Budget previsto' : 'Planned budget',
                            style: const TextStyle(color: _muted),
                          ),
                          const SizedBox(height: 16),
                          if (spending == null)
                            Text(
                              '— ${widget.displayCurrency}',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 18,
                              ),
                            )
                          else
                            BudgetDisplayAmount(
                              minorUnits: spending.spent,
                              originalCurrency: budget.currency,
                              displayCurrency: widget.displayCurrency,
                              fontSize: 18,
                            ),
                          Text(
                            it
                                ? 'Spesa a tuo carico '
                                      '(pagata e da saldare)'
                                : 'Your share '
                                      '(paid and outstanding)',
                            style: const TextStyle(color: _muted),
                          ),
                          const SizedBox(height: 14),
                          if (incomplete)
                            Text(
                              it
                                  ? 'Rimanente non determinabile: '
                                        'manca un importo o un tasso di cambio.'
                                  : 'Remaining unavailable: '
                                        'an amount or exchange rate is missing.',
                              style: const TextStyle(color: _gold),
                            )
                          else ...[
                            Text(
                              exceeded
                                  ? (it ? 'Oltre il budget' : 'Over budget')
                                  : (it ? 'Disponibile' : 'Remaining'),
                              style: const TextStyle(color: _muted),
                            ),
                            BudgetDisplayAmount(
                              minorUnits: remaining.abs(),
                              originalCurrency: budget.currency,
                              displayCurrency: widget.displayCurrency,
                              fontSize: 23,
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
                                      'Exceeding the budget never blocks expenses.',
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
