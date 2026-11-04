import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import 'budget_api.dart';
import 'budget_category_picker.dart';

class BudgetCategoryEditDialog extends StatefulWidget {
  const BudgetCategoryEditDialog({
    super.key,
    required this.api,
    required this.expenseId,
    required this.private,
    required this.initialCategory,
  });

  final BudgetApi api;
  final String expenseId;
  final bool private;
  final String initialCategory;

  @override
  State<BudgetCategoryEditDialog> createState() =>
      _BudgetCategoryEditDialogState();
}

class _BudgetCategoryEditDialogState extends State<BudgetCategoryEditDialog> {
  late String _selected = widget.initialCategory;
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    setState(() { _busy = true; _error = null; });
    try {
      await widget.api.updateExpenseCategory(
        expenseId: widget.expenseId,
        private: widget.private,
        category: _selected,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: const Color(0xFF241A16),
      title: Text(l10n.b6EditCategory),
      content: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BudgetCategoryPicker(
              api: widget.api,
              selected: _selected,
              enabled: !_busy,
              onChanged: (value) => setState(() => _selected = value),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Color(0xFFFFB4A2))),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.b6Cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(l10n.b6Save),
        ),
      ],
    );
  }
}