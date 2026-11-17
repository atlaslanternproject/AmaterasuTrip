// Parte di budget_revision_panel.dart: lettura degli importi
// e chiamate al server per proporre e decidere.

// ignore_for_file: invalid_use_of_protected_member
part of 'budget_revision_panel.dart';

extension _BudgetRevisionPanelStateActions on _BudgetRevisionPanelState {
  Map<String, dynamic> _map(dynamic raw) {
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  int _units(dynamic raw) {
    final value = _map(raw)['minorUnits'];
    return value is int ? value : 0;
  }

  String _formatted(int minor, String currency) {
    return BudgetMoneyFormatter.format(
      minor,
      currency,
      decimalSeparator: '.',
      includeCurrency: false,
    );
  }

  int? _parse(String text, String currency) {
    try {
      return BudgetMoneyInput.parse(text, currency, allowZero: true);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  Future<void> _call(String name, Map<String, dynamic> payload) async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
      _feedback = null;
    });

    try {
      await _functions.httpsCallable(name).call(payload);

      if (!mounted) {
        return;
      }

      setState(() {
        _feedback = AppLocalizations.of(context)!.budgetRevisionSent;
      });
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _feedback = '${error.code}: ${error.message ?? ''}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _feedback = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _decide(String proposalId, bool approved) async {
    await _call('approveBudgetRevision', {
      'tripId': widget.api.tripId,
      'expenseId': widget.expenseId,
      'proposalId': proposalId,
      'approved': approved,
    });
  }
}
