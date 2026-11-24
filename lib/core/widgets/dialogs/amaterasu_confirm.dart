// Conferma nel pannello dell'app: icona, titolo, testo breve, pulsante
// principale e secondario. Le azioni distruttive sono rosse e chiedono una
// seconda conferma nello stesso pannello (niente popup sopra popup).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'amaterasu_sheet.dart';

/// True when the user confirmed (twice for destructive actions).
Future<bool> confirmAmaterasuAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
  IconData? icon,
  String keyPrefix = 'confirm',
}) async {
  final result = await showAmaterasuSheet<bool>(
    context,
    builder: (_) => _ConfirmPanel(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      destructive: destructive,
      icon: icon,
      keyPrefix: keyPrefix,
    ),
  );
  return result ?? false;
}

class _ConfirmPanel extends StatefulWidget {
  const _ConfirmPanel({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.destructive,
    required this.icon,
    required this.keyPrefix,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final bool destructive;
  final IconData? icon;
  final String keyPrefix;

  @override
  State<_ConfirmPanel> createState() => _ConfirmPanelState();
}

class _ConfirmPanelState extends State<_ConfirmPanel> {
  bool _second = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final icon = widget.icon;
    void confirm() => widget.destructive && !_second
        ? setState(() => _second = true)
        : Navigator.pop(context, true);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 28,
              color: widget.destructive
                  ? AmaterasuColors.error
                  : AmaterasuColors.accentBudget,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            widget.title,
            style: const TextStyle(
              color: AmaterasuColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _second ? l10n.uiConfirmAgain : widget.body,
            key: Key('${widget.keyPrefix}-body'),
            style: const TextStyle(
              color: AmaterasuColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              AmaterasuButton.secondary(
                key: Key('${widget.keyPrefix}-cancel'),
                label: l10n.uiCancel,
                onPressed: () => Navigator.pop(context, false),
              ),
              AmaterasuButton(
                key: Key('${widget.keyPrefix}-ok'),
                kind: widget.destructive
                    ? AmaterasuButtonKind.destructive
                    : AmaterasuButtonKind.primary,
                label: _second ? l10n.uiConfirmYes : widget.confirmLabel,
                onPressed: confirm,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
