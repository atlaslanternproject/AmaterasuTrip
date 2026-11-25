// Parte di budget_create_dialog.dart: caricamento dei viaggiatori
// e salvataggio della spesa.

// ignore_for_file: invalid_use_of_protected_member
part of 'budget_create_dialog.dart';

extension _BudgetCreateDialogStateSave on _BudgetCreateDialogState {
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

  Future<void> _save() async {
    if (_saving) return;

    try {
      setState(() {
        _saving = true;
        _error = null;
      });

      final minorUnits = _totalMinor();
      final link = _link.text.trim();
      if (link.isNotEmpty && !AmaterasuWebLink.isValid(link)) {
        throw FormatException(
          budgetL10n(
            Localizations.localeOf(context).languageCode == 'it',
          ).btCreateLinkInvalid,
        );
      }

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

      final expenseId = await widget.api.create(
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
        source: widget.source,
        link: link.isEmpty ? null : link,
      );
      widget.onCreated?.call(expenseId);

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
}
