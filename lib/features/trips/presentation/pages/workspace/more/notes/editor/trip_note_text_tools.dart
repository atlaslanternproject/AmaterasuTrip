// Strumenti del testo di una nota: i modelli pronti per le note nuove
// (Info utili, Frasi utili, Contatti) e la barra di formattazione di base
// (titolo "# ", elenco "- ", grassetto ** **) che scrive i segni nel testo.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripNoteTemplates extends StatelessWidget {
  const TripNoteTemplates({super.key, required this.onPick});

  final void Function(String title, String body) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget button(
      String key,
      IconData icon,
      String label,
      String t,
      String b,
    ) => TextButton.icon(
      key: Key('note-template-$key'),
      onPressed: () => onPick(t, b),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
    return Wrap(
      spacing: 4,
      children: [
        button(
          'useful',
          Icons.wifi_rounded,
          l10n.noteTemplateUseful,
          l10n.noteTemplateUsefulTitle,
          l10n.noteTemplateUsefulBody,
        ),
        button(
          'phrases',
          Icons.translate_rounded,
          l10n.noteTemplatePhrases,
          l10n.noteTemplatePhrasesTitle,
          l10n.noteTemplatePhrasesBody,
        ),
        button(
          'contacts',
          Icons.contact_phone_outlined,
          l10n.noteTemplateContacts,
          l10n.noteTemplateContactsTitle,
          l10n.noteTemplateContactsBody,
        ),
      ],
    );
  }
}

/// Writes the formatting marks in [controller] at the cursor (or around
/// the selected text for bold).
class TripNoteFormatBar extends StatelessWidget {
  const TripNoteFormatBar({super.key, required this.controller});

  final TextEditingController controller;

  void _linePrefix(String prefix) {
    final text = controller.text;
    final at = controller.selection.isValid
        ? controller.selection.start
        : text.length;
    final lineStart = text.lastIndexOf('\n', at == 0 ? 0 : at - 1) + 1;
    controller.value = TextEditingValue(
      text: text.replaceRange(lineStart, lineStart, prefix),
      selection: TextSelection.collapsed(offset: at + prefix.length),
    );
  }

  void _bold() {
    final text = controller.text;
    final sel = controller.selection.isValid
        ? controller.selection
        : TextSelection.collapsed(offset: text.length);
    final inner = sel.textInside(text);
    controller.value = TextEditingValue(
      text: text.replaceRange(sel.start, sel.end, '**$inner**'),
      selection: TextSelection.collapsed(offset: sel.start + inner.length + 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        IconButton(
          key: const Key('note-format-title'),
          tooltip: l10n.noteFormatTitle,
          onPressed: () => _linePrefix('# '),
          icon: const Icon(Icons.title_rounded),
        ),
        IconButton(
          key: const Key('note-format-list'),
          tooltip: l10n.noteFormatList,
          onPressed: () => _linePrefix('- '),
          icon: const Icon(Icons.format_list_bulleted_rounded),
        ),
        IconButton(
          key: const Key('note-format-bold'),
          tooltip: l10n.noteFormatBold,
          onPressed: _bold,
          icon: const Icon(Icons.format_bold_rounded),
        ),
      ],
    );
  }
}
