// Sezione a tendina degli editor: icona, titolo e freccia; da chiusa
// mostra una riga di riepilogo. Con [forceOpen] resta aperta (es. quando
// contiene un errore). Stesso aspetto dei blocchi degli editor.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';

class AmaterasuFoldSection extends StatefulWidget {
  const AmaterasuFoldSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.summary,
    this.initiallyOpen = true,
    this.forceOpen = false,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  /// One line shown when the section is closed.
  final String? summary;
  final bool initiallyOpen;
  final bool forceOpen;

  @override
  State<AmaterasuFoldSection> createState() => _AmaterasuFoldSectionState();
}

class _AmaterasuFoldSectionState extends State<AmaterasuFoldSection> {
  late bool _open = widget.initiallyOpen;

  bool get _shown => _open || widget.forceOpen;

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AmaterasuColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AmaterasuColors.borderWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _open = !_shown),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: AmaterasuColors.accentBudget,
                  ),
                  const SizedBox(width: AmaterasuSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: AmaterasuColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!_shown && summary != null && summary.isNotEmpty)
                          Text(
                            summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AmaterasuColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _shown ? Icons.expand_less : Icons.expand_more,
                    color: AmaterasuColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_shown)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children,
              ),
            ),
        ],
      ),
    );
  }
}
