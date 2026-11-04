import 'package:flutter/material.dart';
import 'budget_api.dart';
import 'budget_category_picker.dart';
import 'budget_money_input.dart';
import 'budget_currency.dart';
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
        _amount.clear();
        for (final controller in _shareInputs.values) {
          controller.clear();
        }
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    try {
      setState(() {
        _saving = true;
        _error = null;
      });

      final minorUnits = BudgetMoneyInput.parse(
        _amount.text,
        _selectedCurrency,
      );

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
          final value = BudgetMoneyInput.parse(input, _selectedCurrency);

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

      await widget.api.create(
        customShares: customShares,
        title: _title.text,
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

    return AlertDialog(
      backgroundColor: const Color(0xFF231915),
      title: Text(
        it ? 'Nuova spesa' : 'New expense',
        style: const TextStyle(color: Color(0xFFF2E7D5)),
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(it ? '1. Dettagli' : '1. Details'),
                      selected: _step == 0,
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _step = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(it ? '2. Importo' : '2. Amount'),
                      selected: _step == 1,
                      onSelected: _saving
                          ? null
                          : (_) {
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
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_step == 0) ...[
                TextField(
                  controller: _title,
                  enabled: !_saving,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: it ? 'Nome della spesa' : 'Expense name',
                    hintText: it ? 'Es. Hotel a Kyoto' : 'E.g. Kyoto hotel',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
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
                  maxLines: 3,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    labelText: it ? 'Note (facoltative)' : 'Notes (optional)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Text(it ? 'Condivisa' : 'Shared'),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text(it ? 'Personale' : 'Personal'),
                    ),
                  ],
                  selected: {_shared},
                  onSelectionChanged: _saving
                      ? null
                      : (value) => setState(() => _shared = value.first),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickCurrency,
                  icon: const Icon(Icons.currency_exchange_rounded),
                  label: Text(
                    '${it ? "Valuta della spesa" : "Expense currency"}: $_selectedCurrency',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amount,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: it ? 'Importo' : 'Amount',
                    suffixText: _selectedCurrency,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: InputDecoration(
                    labelText: it ? 'Stato' : 'Status',
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
                      child: Text(it ? 'Pagata da me' : 'Paid by me'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _status = value ?? 'planned'),
                ),
                if (_shared) ...[
                  const SizedBox(height: 16),
                  Text(
                    it
                        ? 'Come dividere la spesa?'
                        : 'How to split the expense?',
                    style: const TextStyle(
                      color: Color(0xFFF2E7D5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(it ? 'Quote uguali' : 'Equal shares'),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(it ? 'Personalizzate' : 'Custom shares'),
                      ),
                    ],
                    selected: {_customSplit},
                    onSelectionChanged: _saving
                        ? null
                        : (values) =>
                              setState(() => _customSplit = values.first),
                  ),
                  if (_customSplit) ...[
                    const SizedBox(height: 12),
                    Text(
                      it
                          ? 'Inserisci la quota per ogni partecipante selezionato.'
                          : 'Enter each selected participant\'s share.',
                      style: const TextStyle(
                        color: Color(0xFFB7A99B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._travelers
                        .where((person) => _selected.contains(person['uid']))
                        .map((person) {
                          final uid = person['uid']!;
                          final controller = _shareInputs.putIfAbsent(
                            uid,
                            () => TextEditingController(),
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextField(
                              controller: controller,
                              enabled: !_saving,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: person['name'],
                                suffixText: _selectedCurrency,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          );
                        }),
                  ],
                ],
                if (_shared) ...[
                  const SizedBox(height: 18),
                  Text(
                    it ? 'Dividi tra' : 'Split between',
                    style: const TextStyle(
                      color: Color(0xFFF2E7D5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._travelers.map((person) {
                    final uid = person['uid']!;
                    return CheckboxListTile(
                      value: _selected.contains(uid),
                      title: Text(person['name']!),
                      dense: true,
                      onChanged: _saving
                          ? null
                          : (checked) => setState(() {
                              if (checked == true) {
                                _selected.add(uid);
                              } else {
                                _selected.remove(uid);
                              }
                            }),
                    );
                  }),
                ],
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFFFB4A2))),
              ],
              const SizedBox(height: 12),
              Text(
                it
                    ? 'Prima versione: quote uguali. I pagamenti di altri '
                          'viaggiatori richiederanno conferma.'
                    : 'First version: equal shares. Payments made by '
                          'other travelers require approval.',
                style: const TextStyle(color: Color(0xFFB7A99B), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(it ? 'Annulla' : 'Cancel'),
        ),
        FilledButton(
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
          child: Text(
            _step == 0
                ? (it ? 'Continua' : 'Continue')
                : (it ? 'Salva spesa' : 'Save expense'),
          ),
        ),
      ],
    );
  }
}
