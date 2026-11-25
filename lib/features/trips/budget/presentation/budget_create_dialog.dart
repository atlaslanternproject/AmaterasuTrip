// Dialogo per creare una spesa: tipo (con tutti, con alcune persone,
// personale, anticipata per altri), titolo, importo totale o a persona,
// valuta, data, partecipanti con "Tutti", pagatori, categoria, metodi di
// pagamento, link facoltativo e sezione di origine (aperto dalle sezioni).

import 'package:amaterasutrip/core/widgets/common/amaterasu_loader.dart';
import 'package:flutter/material.dart';
import 'budget_dialog_chrome.dart';
import 'budget_create_section.dart';
import 'budget_traveler_tile.dart';
import '../calculations/budget_expense_split_preview.dart';
import '../calculations/budget_money_formatter.dart';
import 'budget_api.dart';
import 'budget_category_picker.dart';
import 'budget_money_input.dart';
import 'budget_currency_choice.dart';
import 'budget_payment_methods_editor.dart';
import '../models/budget_payment_allocation.dart';
import '../models/budget_payment_plan.dart';
import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_l10n.dart';

part 'budget_create_dialog_currency.dart';
part 'budget_create_dialog_kind.dart';
part 'budget_create_dialog_preview.dart';
part 'budget_create_dialog_save.dart';

class BudgetCreateDialog extends StatefulWidget {
  const BudgetCreateDialog({
    super.key,
    required this.api,
    required this.currency,
    this.initialTitle,
    this.initialCategory,
    this.initialDate,
    this.initialMinorUnits,
    this.sharedOnly = false,
    this.onCreated,
    this.source,
  });

  final BudgetApi api;
  final String currency;

  /// Optional values to start from (e.g. an expense created from a stay).
  final String? initialTitle;
  final String? initialCategory;
  final DateTime? initialDate;
  final int? initialMinorUnits;

  /// When true only a shared expense can be created.
  final bool sharedOnly;

  /// Called with the ID of the created expense, before the dialog closes.
  final void Function(String expenseId)? onCreated;

  /// Section and item that open the dialog ("Go to the transport").
  final (String, String)? source;

  @override
  State<BudgetCreateDialog> createState() => _BudgetCreateDialogState();
}

class _BudgetCreateDialogState extends State<BudgetCreateDialog> {
  late DateTime _expenseDate = DateUtils.dateOnly(
    widget.initialDate ?? DateTime.now(),
  );
  late final _title = TextEditingController(text: widget.initialTitle ?? '');
  final _notes = TextEditingController();
  final _link = TextEditingController();
  String _kind = 'some';
  bool _perPerson = false;
  late String _category = widget.initialCategory ?? 'other';

  late final _amount = TextEditingController(
    text: widget.initialMinorUnits == null
        ? ''
        : BudgetMoneyInput.plainText(
            widget.initialMinorUnits!,
            widget.currency,
          ),
  );
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

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _link.dispose();
    _amount.dispose();
    for (final controller in _shareInputs.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // TODO(audit): build di ~415 righe: estrarre sezioni in widget dedicati per scendere sotto le 200 righe (stesso aspetto).
  @override
  Widget build(BuildContext context) {
    final it = Localizations.localeOf(context).languageCode == 'it';
    const cream = AmaterasuColors.textPrimary;
    const orange = AmaterasuColors.accentOrange;

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
        title: budgetL10n(it).btCreateNewExpense,
        subtitle: _step == 0
            ? (budgetL10n(it).btCreateEssentialDetails)
            : (budgetL10n(it).btCreateAmountsAndTravelers),
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
                    label: budgetL10n(it).btCreate1Details,
                    icon: Icons.edit_note_rounded,
                    selected: _step == 0,
                    onTap: () => setState(() => _step = 0),
                  ),
                  const SizedBox(width: AmaterasuSpacing.sm),
                  modeButton(
                    label: budgetL10n(it).btCreate2Amounts,
                    icon: Icons.payments_outlined,
                    selected: _step == 1,
                    onTap: () {
                      if (_title.text.trim().isEmpty) {
                        setState(() {
                          _error = budgetL10n(it).btCreateEnterAnExpenseName;
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
                  title: budgetL10n(it).btCreateExpenseType,
                  icon: Icons.account_balance_wallet_outlined,
                  subtitle: budgetL10n(it).btCreateChooseWhoCanSee,
                  children: [_kindSelector(it, modeButton)],
                ),
                BudgetCreateSection(
                  title: budgetL10n(it).btCreateExpenseDetails,
                  icon: Icons.receipt_long_outlined,
                  children: [
                    TextField(
                      controller: _title,
                      enabled: !_saving,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: budgetL10n(it).btCreateExpenseName,
                        hintText: budgetL10n(it).btCreateEGKyotoHotel,
                        prefixIcon: const Icon(Icons.edit_outlined),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AmaterasuSpacing.sm),
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(budgetL10n(it).btCreateExpenseDate),
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
                        labelText: budgetL10n(it).btCreateNotesOptional,
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AmaterasuSpacing.sm),
                    _linkField(it),
                  ],
                ),
              ] else ...[
                BudgetCreateSection(
                  title: budgetL10n(it).btCreateExpenseAmount,
                  icon: Icons.currency_exchange_rounded,
                  accent: true,
                  children: [
                    BudgetCurrencyButton(
                      currency: _selectedCurrency,
                      label: budgetL10n(it).btCurrencyLabel,
                      onPressed: _saving ? null : _pickCurrency,
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
                        labelText: _shared && _perPerson
                            ? budgetL10n(it).btCreatePricePerPerson
                            : budgetL10n(it).btCreateTotalAmount,
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
                        labelText: budgetL10n(it).btCreateExpenseStatus,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'planned',
                          child: Text(budgetL10n(it).btStatusPlanned),
                        ),
                        DropdownMenuItem(
                          value: 'outstanding',
                          child: Text(budgetL10n(it).btStatusOutstanding),
                        ),
                        DropdownMenuItem(
                          value: 'paid',
                          child: Text(budgetL10n(it).btStatusPaid),
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
                    title: budgetL10n(it).btCreateSplitBetweenTravelers,
                    icon: Icons.groups_outlined,
                    children: [
                      _perPersonSelector(it, modeButton),
                      const SizedBox(height: AmaterasuSpacing.sm),
                      if (!_perPerson)
                        Row(
                          children: [
                            modeButton(
                              label: budgetL10n(it).btCreateEqualShares,
                              icon: Icons.balance_outlined,
                              selected: !_customSplit,
                              onTap: () => setState(() => _customSplit = false),
                            ),
                            const SizedBox(width: AmaterasuSpacing.sm),
                            modeButton(
                              label: budgetL10n(it).btCreateCustomShares,
                              icon: Icons.tune_rounded,
                              selected: _customSplit,
                              onTap: () => setState(() => _customSplit = true),
                            ),
                          ],
                        ),
                      _allButton(it),
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
                                labelText: budgetL10n(
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
                    title: budgetL10n(it).btCreateHowWasItPaid,
                    icon: Icons.credit_card_outlined,
                    subtitle: budgetL10n(it).btCreateRecordOnlyPaymentsYou,
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
                  title: budgetL10n(it).btCreateSummary,
                  icon: Icons.fact_check_outlined,
                  children: [_expensePreview(it)],
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: AmaterasuSpacing.sm),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AmaterasuColors.accentPeach,
                    fontSize: 13,
                  ),
                ),
              ],

              if (_saving) ...[
                const SizedBox(height: 12),
                const AmaterasuLoader(),
              ],
              const SizedBox(height: AmaterasuSpacing.xs),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(budgetL10n(it).btActionCancel),
        ),
        if (_step == 1)
          TextButton(
            onPressed: _saving
                ? null
                : () => setState(() {
                    _step = 0;
                    _error = null;
                  }),
            child: Text(budgetL10n(it).btCreateBack),
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
                      _error = budgetL10n(it).btCreateEnterAnExpenseName;
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
                ? (budgetL10n(it).btCreateContinue)
                : (budgetL10n(it).btCreateSaveExpense),
          ),
        ),
      ],
    );
  }
}
