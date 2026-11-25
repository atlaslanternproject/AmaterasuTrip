// Parte di budget_create_dialog.dart: tipo di spesa (condivisa con tutti,
// con alcune persone, personale, anticipata per altri), scelta "Totale da
// dividere / Per persona" (il totale si calcola prima dell'invio),
// pulsante "Tutti" e link facoltativo. Nessun cambiamento ai calcoli.

// ignore_for_file: invalid_use_of_protected_member
part of 'budget_create_dialog.dart';

typedef _ModeButton =
    Widget Function({
      required String label,
      required IconData icon,
      required bool selected,
      required VoidCallback onTap,
    });

extension _BudgetCreateDialogKind on _BudgetCreateDialogState {
  /// Amount to send: the price times the participants when "per person".
  int _totalMinor() {
    final value = BudgetMoneyInput.parse(_amount.text, _selectedCurrency);
    return _shared && _perPerson ? value * _selected.length : value;
  }

  void _setKind(String kind) => setState(() {
    _kind = kind;
    _shared = kind != 'personal';
    final me = widget.api.currentUid;
    if (kind == 'all') {
      _selected.addAll([for (final t in _travelers) ?t['uid']]);
    } else if (kind == 'advance') {
      _selected.remove(me);
    } else if (kind == 'some' && _selected.isEmpty) {
      _selected.add(me);
    }
  });

  Widget _kindSelector(bool it, _ModeButton modeButton) {
    final t = budgetL10n(it);
    Widget button(String kind, String label, IconData icon) => modeButton(
      label: label,
      icon: icon,
      selected: _kind == kind,
      onTap: () => _setKind(kind),
    );
    return Column(
      children: [
        Row(
          children: [
            button('all', t.btCreateKindAll, Icons.groups_outlined),
            const SizedBox(width: AmaterasuSpacing.sm),
            button('some', t.btCreateKindSome, Icons.group_outlined),
          ],
        ),
        const SizedBox(height: AmaterasuSpacing.sm),
        Row(
          children: [
            button('advance', t.btCreateKindAdvance, Icons.volunteer_activism),
            if (!widget.sharedOnly) ...[
              const SizedBox(width: AmaterasuSpacing.sm),
              button(
                'personal',
                t.btCreatePersonal,
                Icons.lock_outline_rounded,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _perPersonSelector(bool it, _ModeButton modeButton) {
    final t = budgetL10n(it);
    return Row(
      children: [
        modeButton(
          label: t.btCreateTotalToSplit,
          icon: Icons.functions_rounded,
          selected: !_perPerson,
          onTap: () => setState(() => _perPerson = false),
        ),
        const SizedBox(width: AmaterasuSpacing.sm),
        modeButton(
          label: t.btCreatePerPerson,
          icon: Icons.person_outline_rounded,
          selected: _perPerson,
          onTap: () => setState(() {
            _perPerson = true;
            _customSplit = false;
          }),
        ),
      ],
    );
  }

  Widget _allButton(bool it) => Align(
    alignment: Alignment.centerRight,
    child: TextButton.icon(
      key: const Key('budget-create-all'),
      onPressed: _saving
          ? null
          : () => setState(
              () => _selected.addAll([for (final t in _travelers) ?t['uid']]),
            ),
      icon: const Icon(Icons.done_all_rounded, size: 18),
      label: Text(budgetL10n(it).btCreateAllTravelers),
    ),
  );

  Widget _linkField(bool it) => TextField(
    key: const Key('budget-create-link'),
    controller: _link,
    enabled: !_saving,
    keyboardType: TextInputType.url,
    decoration: InputDecoration(
      labelText: budgetL10n(it).btCreateLinkOptional,
      prefixIcon: const Icon(Icons.link_outlined),
      border: const OutlineInputBorder(),
    ),
  );
}
