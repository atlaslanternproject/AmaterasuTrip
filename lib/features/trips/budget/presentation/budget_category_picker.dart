import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import 'budget_api.dart';

class BudgetCategoryPicker extends StatelessWidget {
  const BudgetCategoryPicker({
    super.key,
    required this.api,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final BudgetApi api;
  final String selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  static const _ids = <String>[
    'accommodation',
    'food',
    'transport',
    'activities',
    'shopping',
    'other',
  ];

  static String label(String id, bool it) {
    switch (id) {
      case 'accommodation':
        return it ? 'Alloggio' : 'Accommodation';
      case 'food':
        return it ? 'Cibo e bevande' : 'Food & drinks';
      case 'transport':
        return it ? 'Trasporti' : 'Transport';
      case 'activities':
        return it ? 'Attività' : 'Activities';
      case 'shopping':
        return 'Shopping';
      case 'other':
        return it ? 'Altro' : 'Other';
      default:
        return id;
    }
  }

  Future<void> _create(BuildContext context) async {
    final added = await showDialog<String>(
      context: context,
      builder: (_) => _NewBudgetCategoryDialog(api: api),
    );
    if (added != null) {
      onChanged(added);
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = Localizations.localeOf(context).languageCode == 'it';
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<Map<String, String>>(
      stream: api.budgetCategories(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? const <String, String>{};
        final ids = <String>{..._ids, ...categories.keys};
        // A just-created category may reach the picker before its stream event.
        ids.add(selected);
        final sorted = ids.toList()
          ..sort(
            (a, b) => (categories[a] ?? label(a, it)).compareTo(
              categories[b] ?? label(b, it),
            ),
          );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey(selected),
              initialValue: selected,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.b6Category,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final id in sorted)
                  DropdownMenuItem<String>(
                    value: id,
                    child: Text(categories[id] ?? label(id, it)),
                  ),
              ],
              onChanged: enabled
                  ? (value) {
                      if (value != null) {
                        onChanged(value);
                      }
                    }
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: enabled ? () => _create(context) : null,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.b6CreateCategory),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A route owns its text controller until Flutter unmounts the route.
class _NewBudgetCategoryDialog extends StatefulWidget {
  const _NewBudgetCategoryDialog({required this.api});
  final BudgetApi api;

  @override
  State<_NewBudgetCategoryDialog> createState() =>
      _NewBudgetCategoryDialogState();
}

class _NewBudgetCategoryDialogState extends State<_NewBudgetCategoryDialog> {
  final _text = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await widget.api.createBudgetCategory(_text.text);
      if (mounted) {
        Navigator.pop(context, id);
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
      title: Text(l10n.b6CreateCategory),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _text,
              maxLength: 60,
              decoration: InputDecoration(
                labelText: l10n.b6CategoryName,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
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
        FilledButton(onPressed: _busy ? null : _save, child: Text(l10n.b6Save)),
      ],
    );
  }
}
