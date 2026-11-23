// Cornice comune degli editor delle sezioni: dialogo largo al massimo 640
// punti (margini ridotti su telefono), titolo, blocchi scorrevoli, messaggi
// dei problemi trovati e pulsanti Annulla / Salva.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

/// Opens [editor] in a dialog; true when it was saved (it pops with true).
Future<bool> showTripSectionEditor(BuildContext context, Widget editor) async {
  final narrow = MediaQuery.sizeOf(context).width < 600;
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: AmaterasuColors.surfaceCard,
      insetPadding: EdgeInsets.all(narrow ? 8 : 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: editor,
      ),
    ),
  );
  return saved ?? false;
}

class TripSectionEditorFrame extends StatelessWidget {
  const TripSectionEditorFrame({
    super.key,
    required this.keyPrefix,
    required this.title,
    required this.children,
    required this.messages,
    required this.saving,
    required this.onSave,
  });

  final String keyPrefix;
  final String title;
  final List<Widget> children;
  final List<String> messages;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AmaterasuColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: children),
          ),
        ),
        for (final message in messages)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              message,
              key: Key('$keyPrefix-editor-error'),
              style: const TextStyle(
                color: AmaterasuColors.accentErrorSoft,
                fontSize: 13,
              ),
            ),
          ),
        if (saving) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context, false),
                child: Text(l10n.sectionsCancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: Key('$keyPrefix-save'),
                style: FilledButton.styleFrom(
                  backgroundColor: AmaterasuColors.accentBudget,
                ),
                onPressed: saving ? null : onSave,
                child: Text(l10n.sectionsSave),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Saving logic shared by the section editors: checks the problems, shows
/// them, saves, closes on success and shows a message on failure.
mixin TripSectionEditorSave<W extends StatefulWidget> on State<W> {
  List<String> messages = const [];
  bool saving = false;

  Future<void> saveWith({
    required List<String> problems,
    required Future<void> Function() save,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (problems.isNotEmpty) {
      setState(() => messages = problems.toSet().toList());
      return;
    }
    setState(() {
      saving = true;
      messages = const [];
    });
    try {
      await save();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => messages = [l10n.sectionsSaveError]);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
