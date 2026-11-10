import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
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
        languageCode: _l10n(it).btCreateEn,
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
          title: _l10n(it).btCreateExpenseCurrency,
          searchHint: _l10n(it).btCreateSearchCurrencies,
          noResultsText: _l10n(it).btCreateNoCurrenciesFound,
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
      return _l10n(it).btCreateYou;
    }

    for (final traveler in _travelers) {
      if (traveler['uid'] == uid) {
        return traveler['name'] ?? (_l10n(it).btCreateTraveler);
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
          _l10n(it).btCreatePaymentsExceedTotal,
          style: const TextStyle(color: Color(0xFFFFB4A2)),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n(it).btCreateSplitPreview,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${_l10n(it).btCreateRecordedBy}: ${_travelerName(widget.api.currentUid, it)}',
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
            '${_l10n(it).btCreateTotal}: ${BudgetMoneyFormatter.format(total, _selectedCurrency)}',
            style: TextStyle(color: color),
          ),
          Text(
            '${_l10n(it).btCreateDeclaredPayments}: ${BudgetMoneyFormatter.format(paid, _selectedCurrency)}',
            style: TextStyle(color: muted),
          ),
          Text(
            '${_l10n(it).btCreateRemaining}: ${BudgetMoneyFormatter.format(total - paid, _selectedCurrency)}',
            style: TextStyle(color: muted),
          ),
        ],
      );
    } catch (_) {
      return Text(
        _l10n(it).btCreateCompleteTheAmountParticipants,
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
          _l10n(it).btCreateConfirmNewExpense,
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
                  '${_l10n(it).btCreateCategory}: $_category',
                  style: const TextStyle(color: Color(0xFFB7A99B)),
                ),
                Text(
                  '${_l10n(it).btCreateType}: ${_shared ? (_l10n(it).btCreateShared) : (_l10n(it).btCreatePersonal)}',
                  style: const TextStyle(color: Color(0xFFB7A99B)),
                ),
                Text(
                  '${_l10n(it).btCreateStatus}: $_status',
                  style: const TextStyle(color: Color(0xFFB7A99B)),
                ),
                const SizedBox(height: 16),
                _expensePreview(it),
                const SizedBox(height: 14),
                Text(
                  _l10n(it).btCreatePaymentsRecordedInThis,
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
            child: Text(_l10n(it).btCreateBackToEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_l10n(it).btCreateConfirmAndSave),
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
        title: _l10n(it).btCreateNewExpense,
        subtitle: _step == 0
            ? (_l10n(it).btCreateEssentialDetails)
            : (_l10n(it).btCreateAmountsAndTravelers),
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
                    label: _l10n(it).btCreate1Details,
                    icon: Icons.edit_note_rounded,
                    selected: _step == 0,
                    onTap: () => setState(() => _step = 0),
                  ),
                  const SizedBox(width: 8),
                  modeButton(
                    label: _l10n(it).btCreate2Amounts,
                    icon: Icons.payments_outlined,
                    selected: _step == 1,
                    onTap: () {
                      if (_title.text.trim().isEmpty) {
                        setState(() {
                          _error = _l10n(it).btCreateEnterAnExpenseName;
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
                  title: _l10n(it).btCreateExpenseType,
                  icon: Icons.account_balance_wallet_outlined,
                  subtitle: _l10n(it).btCreateChooseWhoCanSee,
                  children: [
                    Row(
                      children: [
                        modeButton(
                          label: _l10n(it).btCreateShared,
                          icon: Icons.groups_outlined,
                          selected: _shared,
                          onTap: () => setState(() => _shared = true),
                        ),
                        const SizedBox(width: 8),
                        modeButton(
                          label: _l10n(it).btCreatePersonal,
                          icon: Icons.lock_outline_rounded,
                          selected: !_shared,
                          onTap: () => setState(() => _shared = false),
                        ),
                      ],
                    ),
                  ],
                ),
                BudgetCreateSection(
                  title: _l10n(it).btCreateExpenseDetails,
                  icon: Icons.receipt_long_outlined,
                  children: [
                    TextField(
                      controller: _title,
                      enabled: !_saving,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: _l10n(it).btCreateExpenseName,
                        hintText: _l10n(it).btCreateEGKyotoHotel,
                        prefixIcon: const Icon(Icons.edit_outlined),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(_l10n(it).btCreateExpenseDate),
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
                        labelText: _l10n(it).btCreateNotesOptional,
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                BudgetCreateSection(
                  title: _l10n(it).btCreateExpenseAmount,
                  icon: Icons.currency_exchange_rounded,
                  accent: true,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickCurrency,
                      icon: const Icon(Icons.currency_exchange_rounded),
                      label: Text(
                        '${_l10n(it).btCreateCurrency}: $_selectedCurrency',
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
                        labelText: _l10n(it).btCreateTotalAmount,
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
                        labelText: _l10n(it).btCreateExpenseStatus,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'planned',
                          child: Text(_l10n(it).btCreatePlanned),
                        ),
                        DropdownMenuItem(
                          value: 'outstanding',
                          child: Text(_l10n(it).btCreateOutstanding),
                        ),
                        DropdownMenuItem(
                          value: 'paid',
                          child: Text(_l10n(it).btCreatePaid),
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
                    title: _l10n(it).btCreateSplitBetweenTravelers,
                    icon: Icons.groups_outlined,
                    children: [
                      Row(
                        children: [
                          modeButton(
                            label: _l10n(it).btCreateEqualShares,
                            icon: Icons.balance_outlined,
                            selected: !_customSplit,
                            onTap: () => setState(() => _customSplit = false),
                          ),
                          const SizedBox(width: 8),
                          modeButton(
                            label: _l10n(it).btCreateCustomShares,
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
                                labelText: _l10n(
                                  it,
                                ).btCreateShare('${person["name"]}'),
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
                    title: _l10n(it).btCreateHowWasItPaid,
                    icon: Icons.credit_card_outlined,
                    subtitle: _l10n(it).btCreateRecordOnlyPaymentsYou,
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
                  title: _l10n(it).btCreateSummary,
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
          child: Text(_l10n(it).btCreateCancel),
        ),
        if (_step == 1)
          TextButton(
            onPressed: _saving
                ? null
                : () => setState(() {
                    _step = 0;
                    _error = null;
                  }),
            child: Text(_l10n(it).btCreateBack),
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
                      _error = _l10n(it).btCreateEnterAnExpenseName;
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
                ? (_l10n(it).btCreateContinue)
                : (_l10n(it).btCreateSaveExpense),
          ),
        ),
      ],
    );
  }
}

/// Texts of this screen, in the language chosen by the existing `it` flag.
AppLocalizations _l10n(bool it) =>
    lookupAppLocalizations(Locale(it ? 'it' : 'en'));
