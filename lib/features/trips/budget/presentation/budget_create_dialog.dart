import 'package:flutter/material.dart';
import 'budget_dialog_chrome.dart';
import 'budget_create_section.dart';
import 'budget_traveler_tile.dart';
import '../calculations/budget_expense_split_preview.dart';
import '../calculations/budget_money_formatter.dart';
import 'budget_api.dart';
import 'budget_category_picker.dart';
import 'budget_money_input.dart';
import 'budget_currency.dart';
import 'budget_payment_methods_editor.dart';
import '../models/budget_payment_allocation.dart';
import '../models/budget_payment_plan.dart';
import '../../presentation/pages/create_trip/currency/trip_currency_picker_sheet.dart';
import '../../presentation/pages/create_trip/destination/services/destination_places_service.dart';

class BudgetCreateDialog extends StatefulWidget {
  const BudgetCreateDialog({
    super.key,
    required this.api,
    required this.currency,
  });

  final BudgetApi api;
  final String currency;

  @override
  State<BudgetCreateDialog> createState() => _BudgetCreateDialogState();
}

class _BudgetCreateDialogState extends State<BudgetCreateDialog> {
  DateTime _expenseDate = DateUtils.dateOnly(DateTime.now());
  final _title = TextEditingController();
  final _notes = TextEditingController();
  String _category = 'other';

  final _amount = TextEditingController();
  late String _selectedCurrency = widget.currency;
  int _step = 0;
  bool _shared = true;
  bool _saving = false;
  String _status = 'planned';
  String? _error;
  List<Map<String, String>> _travelers = [];
  final Set<String> _selected = {};
  bool _customSplit = false;
  final Map<String, TextEditingController> _shareInputs = {};
  List<BudgetPaymentAllocation> _paymentAllocations = [];

  @override
  void initState() {
    super.initState();
    _loadTravelers();
  }

  Future<void> _loadTravelers() async {
    try {
      final travelers = await widget.api.travelers();
      if (!mounted) return;
      setState(() {
        _travelers = travelers;
        _selected.add(widget.api.currentUid);
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _amount.dispose();
    for (final controller in _shareInputs.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCurrency() async {
    if (_saving) return;

    final it = Localizations.localeOf(context).languageCode == 'it';
    final codes = BudgetCurrency.supported.toSet();
    List<TripCurrency> currencies;

    try {
      final fetched = await const DestinationPlacesService().getCurrencies(
        languageCode: it ? 'it' : 'en',
      );

      currencies = fetched.where((item) {
        return codes.contains(item.code.toUpperCase());
      }).toList();

      final found = currencies.map((e) => e.code.toUpperCase()).toSet();
      currencies.addAll(
        codes
            .difference(found)
            .map((code) => TripCurrency(code: code, name: code, symbol: code)),
      );
    } catch (_) {
      currencies = codes
          .map((code) => TripCurrency(code: code, name: code, symbol: code))
          .toList();
    }

    currencies.sort((a, b) => a.code.compareTo(b.code));

    if (!mounted) return;

    final chosen = await showModalBottomSheet<TripCurrency>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF231915),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: TripCurrencyPickerSheet(
          currencies: currencies,
          selectedCurrency: _selectedCurrency,
          title: it ? 'Valuta della spesa' : 'Expense currency',
          searchHint: it ? 'Cerca una valuta' : 'Search currencies',
          noResultsText: it ? 'Nessuna valuta trovata' : 'No currencies found',
        ),
      ),
    );

    if (!mounted || chosen == null) return;

    final code = BudgetCurrency.normalize(chosen.code);

    if (code != _selectedCurrency) {
      setState(() {
        _selectedCurrency = code;
        _paymentAllocations = [];
        _amount.clear();
        for (final controller in _shareInputs.values) {
          controller.clear();
        }
        _error = null;
      });
    }
  }

  String _travelerName(String uid, bool it) {
    if (uid == widget.api.currentUid) {
      return it ? 'Tu' : 'You';
    }

    for (final traveler in _travelers) {
      if (traveler['uid'] == uid) {
        return traveler['name'] ?? (it ? 'Viaggiatore' : 'Traveler');
      }
    }

    return uid;
  }

  Widget _expensePreview(bool it) {
    final color = const Color(0xFFF2E7D5);
    final muted = const Color(0xFFB7A99B);

    try {
      final total = BudgetMoneyInput.parse(_amount.text, _selectedCurrency);

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
          it ? 'I pagamenti superano il totale.' : 'Payments exceed total.',
          style: const TextStyle(color: Color(0xFFFFB4A2)),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            it ? 'Riepilogo della ripartizione' : 'Split preview',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${it ? "Registrata da" : "Recorded by"}: ${_travelerName(widget.api.currentUid, it)}',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 8),
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
            '${it ? "Totale" : "Total"}: ${BudgetMoneyFormatter.format(total, _selectedCurrency)}',
            style: TextStyle(color: color),
          ),
          Text(
            '${it ? "Pagamenti dichiarati" : "Declared payments"}: ${BudgetMoneyFormatter.format(paid, _selectedCurrency)}',
            style: TextStyle(color: muted),
          ),
          Text(
            '${it ? "Da saldare" : "Remaining"}: ${BudgetMoneyFormatter.format(total - paid, _selectedCurrency)}',
            style: TextStyle(color: muted),
          ),
        ],
      );
    } catch (_) {
      return Text(
        it
            ? 'Completa importo, partecipanti e quote per visualizzare l’anteprima.'
            : 'Complete the amount, participants and shares to see the preview.',
        style: TextStyle(color: muted),
      );
    }
  }

  Future<bool> _confirmExpense(bool it) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF231915),
        title: Text(
          it ? 'Conferma nuova spesa' : 'Confirm new expense',
          style: const TextStyle(color: Color(0xFFF2E7D5)),
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
                    color: Color(0xFFF2E7D5),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${it ? "Categoria" : "Category"}: $_category',
                  style: const TextStyle(color: Color(0xFFB7A99B)),
                ),
                Text(
                  '${it ? "Tipo" : "Type"}: ${_shared ? (it ? "Condivisa" : "Shared") : (it ? "Personale" : "Personal")}',
                  style: const TextStyle(color: Color(0xFFB7A99B)),
                ),
                Text(
                  '${it ? "Stato" : "Status"}: $_status',
                  style: const TextStyle(color: Color(0xFFB7A99B)),
                ),
                const SizedBox(height: 16),
                _expensePreview(it),
                const SizedBox(height: 14),
                Text(
                  it
                      ? 'I pagamenti registrati in questa versione devono essere stati effettuati da te.'
                      : 'Payments recorded in this version must have been made by you.',
                  style: const TextStyle(
                    color: Color(0xFFB7A99B),
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
            child: Text(it ? 'Torna a modificare' : 'Back to editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(it ? 'Conferma e salva' : 'Confirm and save'),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<void> _save() async {
    if (_saving) return;

    try {
      setState(() {
        _saving = true;
        _error = null;
      });

      final minorUnits = BudgetMoneyInput.parse(
        _amount.text,
        _selectedCurrency,
      );

      if (_shared && _selected.isEmpty) {
        throw FormatException(
          Localizations.localeOf(context).languageCode == 'it'
              ? 'Seleziona almeno un partecipante.'
              : 'Select at least one participant.',
        );
      }

      Map<String, int>? customShares;

      if (_shared && _customSplit) {
        if (_selected.isEmpty) {
          throw FormatException(
            Localizations.localeOf(context).languageCode == 'it'
                ? 'Seleziona almeno un partecipante.'
                : 'Select at least one participant.',
          );
        }

        customShares = <String, int>{};
        var sum = 0;

        for (final uid in _selected) {
          final input = _shareInputs[uid]?.text ?? '';
          final value = BudgetMoneyInput.parse(
            input,
            _selectedCurrency,
            allowZero: true,
          );

          customShares[uid] = value;
          sum += value;
        }

        if (sum != minorUnits) {
          throw FormatException(
            Localizations.localeOf(context).languageCode == 'it'
                ? 'La somma delle quote deve essere uguale all\'importo.'
                : 'Shares must add up to the expense total.',
          );
        }
      }

      if (!mounted) return;

      final it = Localizations.localeOf(context).languageCode == 'it';
      final confirmed = await _confirmExpense(it);

      if (!confirmed || !mounted) return;

      await widget.api.create(
        paymentPlan: BudgetPaymentPlan(
          _status == 'planned' ? [] : _paymentAllocations,
        ),
        customShares: customShares,
        title: _title.text,
        expenseDate: _expenseDate,
        category: _category,
        notes: _notes.text,
        shared: _shared,
        currency: _selectedCurrency,
        minorUnits: minorUnits,
        status: _status,
        participants: _shared ? _selected.toList() : [widget.api.currentUid],
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        final message = e is FormatException
            ? e.message.toString()
            : e is ArgumentError
            ? (e.message?.toString() ?? 'Valore non valido.')
            : '$e';

        setState(() => _error = message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = Localizations.localeOf(context).languageCode == 'it';
    const cream = Color(0xFFF2E7D5);
    const orange = Color(0xFFE17A43);

    Widget modeButton({
      required String label,
      required IconData icon,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Material(
          color: selected ? const Color(0xFFDA7742) : const Color(0xFF392820),
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            onTap: _saving ? null : onTap,
            borderRadius: BorderRadius.circular(11),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: selected ? const Color(0xFF180F0B) : cream,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? const Color(0xFF180F0B) : cream,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: BudgetDialogChrome.background,
      shape: BudgetDialogChrome.shape,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      titlePadding: BudgetDialogChrome.titlePadding,
      contentPadding: BudgetDialogChrome.contentPadding,
      actionsPadding: BudgetDialogChrome.actionsPadding,
      title: BudgetDialogChrome.header(
        title: it ? 'Nuova spesa' : 'New expense',
        subtitle: _step == 0
            ? (it ? 'Informazioni essenziali' : 'Essential details')
            : (it ? 'Importi e partecipanti' : 'Amounts and travelers'),
        icon: Icons.receipt_long_outlined,
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  modeButton(
                    label: it ? '1. Dettagli' : '1. Details',
                    icon: Icons.edit_note_rounded,
                    selected: _step == 0,
                    onTap: () => setState(() => _step = 0),
                  ),
                  const SizedBox(width: 8),
                  modeButton(
                    label: it ? '2. Importi' : '2. Amounts',
                    icon: Icons.payments_outlined,
                    selected: _step == 1,
                    onTap: () {
                      if (_title.text.trim().isEmpty) {
                        setState(() {
                          _error = it
                              ? 'Inserisci il nome della spesa.'
                              : 'Enter an expense name.';
                        });
                        return;
                      }
                      setState(() {
                        _error = null;
                        _step = 1;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (_step == 0) ...[
                BudgetCreateSection(
                  title: it ? 'Tipo di spesa' : 'Expense type',
                  icon: Icons.account_balance_wallet_outlined,
                  subtitle: it
                      ? 'Scegli chi potrà vedere questa spesa.'
                      : 'Choose who can see this expense.',
                  children: [
                    Row(
                      children: [
                        modeButton(
                          label: it ? 'Condivisa' : 'Shared',
                          icon: Icons.groups_outlined,
                          selected: _shared,
                          onTap: () => setState(() => _shared = true),
                        ),
                        const SizedBox(width: 8),
                        modeButton(
                          label: it ? 'Personale' : 'Personal',
                          icon: Icons.lock_outline_rounded,
                          selected: !_shared,
                          onTap: () => setState(() => _shared = false),
                        ),
                      ],
                    ),
                  ],
                ),
                BudgetCreateSection(
                  title: it ? 'Informazioni della spesa' : 'Expense details',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    TextField(
                      controller: _title,
                      enabled: !_saving,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: it ? 'Nome della spesa' : 'Expense name',
                        hintText: it ? 'Es. Hotel a Kyoto' : 'E.g. Kyoto hotel',
                        prefixIcon: const Icon(Icons.edit_outlined),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(it ? "Data della spesa" : "Expense date"),
                      subtitle: Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(_expenseDate),
                      ),
                      onTap: _saving
                          ? null
                          : () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _expenseDate,
                                firstDate: DateTime(1900),
                                lastDate: DateTime(9999, 12, 31),
                              );
                              if (mounted && date != null) {
                                setState(() => _expenseDate = date);
                              }
                            },
                    ),
                    BudgetCategoryPicker(
                      api: widget.api,
                      selected: _category,
                      enabled: !_saving,
                      onChanged: (value) => setState(() => _category = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notes,
                      enabled: !_saving,
                      maxLines: 2,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        labelText: it
                            ? 'Note (facoltative)'
                            : 'Notes (optional)',
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                BudgetCreateSection(
                  title: it ? 'Importo della spesa' : 'Expense amount',
                  icon: Icons.currency_exchange_rounded,
                  accent: true,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickCurrency,
                      icon: const Icon(Icons.currency_exchange_rounded),
                      label: Text(
                        '${it ? "Valuta" : "Currency"}: $_selectedCurrency',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amount,
                      enabled: !_saving,
                      onChanged: (_) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        color: cream,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: it ? 'Importo totale' : 'Total amount',
                        suffixText: _selectedCurrency,
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('status-$_status'),
                      initialValue: _status,
                      decoration: InputDecoration(
                        labelText: it ? 'Stato della spesa' : 'Expense status',
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'planned',
                          child: Text(it ? 'Prevista' : 'Planned'),
                        ),
                        DropdownMenuItem(
                          value: 'outstanding',
                          child: Text(it ? 'Da saldare' : 'Outstanding'),
                        ),
                        DropdownMenuItem(
                          value: 'paid',
                          child: Text(it ? 'Pagata' : 'Paid'),
                        ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) => setState(() {
                              _status = value ?? 'planned';
                              _paymentAllocations = [];
                            }),
                    ),
                  ],
                ),
                if (_shared)
                  BudgetCreateSection(
                    title: it
                        ? 'Dividi tra i viaggiatori'
                        : 'Split between travelers',
                    icon: Icons.groups_outlined,
                    children: [
                      Row(
                        children: [
                          modeButton(
                            label: it ? 'Quote uguali' : 'Equal shares',
                            icon: Icons.balance_outlined,
                            selected: !_customSplit,
                            onTap: () => setState(() => _customSplit = false),
                          ),
                          const SizedBox(width: 8),
                          modeButton(
                            label: it ? 'Personalizzate' : 'Custom shares',
                            icon: Icons.tune_rounded,
                            selected: _customSplit,
                            onTap: () => setState(() => _customSplit = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      for (final person in _travelers) ...[
                        BudgetTravelerTile(
                          name: person['name'] ?? '',
                          photoUrl:
                              person['tripPhotoUrl'] ??
                              person['photoUrl'] ??
                              person['avatarUrl'] ??
                              person['profilePhotoUrl'] ??
                              person['pictureUrl'],
                          selected: _selected.contains(person['uid']),
                          enabled: !_saving,
                          onChanged: (selected) => setState(() {
                            final uid = person['uid']!;
                            if (selected) {
                              _selected.add(uid);
                            } else {
                              _selected.remove(uid);
                            }
                          }),
                        ),
                        if (_customSplit &&
                            _selected.contains(person['uid'])) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 12,
                              bottom: 14,
                            ),
                            child: TextField(
                              controller: _shareInputs.putIfAbsent(
                                person['uid']!,
                                () => TextEditingController(),
                              ),
                              enabled: !_saving,
                              onChanged: (_) => setState(() {}),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: it
                                    ? 'Quota di ${person["name"]}'
                                    : '${person["name"]} share',
                                suffixText: _selectedCurrency,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                if (_status != 'planned')
                  BudgetCreateSection(
                    title: it ? 'Come è stata pagata?' : 'How was it paid?',
                    icon: Icons.credit_card_outlined,
                    subtitle: it
                        ? 'Registra solo pagamenti effettuati da te.'
                        : 'Record only payments you actually made.',
                    children: [
                      BudgetPaymentMethodsEditor(
                        key: ValueKey('$_status-$_selectedCurrency'),
                        showAccount: true,
                        currency: _selectedCurrency,
                        payerUid: widget.api.currentUid,
                        enabled: !_saving,
                        onChanged: (value) =>
                            setState(() => _paymentAllocations = value),
                      ),
                    ],
                  ),
                BudgetCreateSection(
                  title: it ? 'Riepilogo' : 'Summary',
                  icon: Icons.fact_check_outlined,
                  children: [_expensePreview(it)],
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFFFB4A2),
                    fontSize: 13,
                  ),
                ),
              ],

              if (_saving) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(color: orange),
              ],
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(it ? 'Annulla' : 'Cancel'),
        ),
        if (_step == 1)
          TextButton(
            onPressed: _saving
                ? null
                : () => setState(() {
                    _step = 0;
                    _error = null;
                  }),
            child: Text(it ? 'Indietro' : 'Back'),
          ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: orange,
            foregroundColor: const Color(0xFF170E0A),
          ),
          onPressed: _saving
              ? null
              : _step == 0
              ? () {
                  if (_title.text.trim().isEmpty) {
                    setState(() {
                      _error = it
                          ? 'Inserisci il nome della spesa.'
                          : 'Enter an expense name.';
                    });
                    return;
                  }
                  setState(() {
                    _error = null;
                    _step = 1;
                  });
                }
              : _save,
          icon: Icon(
            _step == 0 ? Icons.arrow_forward_rounded : Icons.check_rounded,
            size: 18,
          ),
          label: Text(
            _step == 0
                ? (it ? 'Continua' : 'Continue')
                : (it ? 'Salva spesa' : 'Save expense'),
          ),
        ),
      ],
    );
  }
}
