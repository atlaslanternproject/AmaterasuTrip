// Parti piccole della card delle sezioni: riquadro con l'icona della
// sezione e riga di dettaglio con icona e testo.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'trip_section_entry.dart';
import 'trip_section_rich_text.dart';

class TripSectionCardBadge extends StatelessWidget {
  const TripSectionCardBadge({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AmaterasuColors.accentBudget.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: AmaterasuColors.accentBudget, size: 22),
  );
}

const _lineStyle = TextStyle(
  color: AmaterasuColors.textSecondary,
  fontSize: 13,
);

class TripSectionCardLine extends StatelessWidget {
  const TripSectionCardLine(this.line, {super.key});

  final TripSectionLine line;

  @override
  Widget build(BuildContext context) => Padding(
    key: line.key,
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(line.icon, size: 16, color: AmaterasuColors.textSecondary),
        const SizedBox(width: AmaterasuSpacing.sm),
        Expanded(
          child: line.formatted
              ? Text.rich(
                  tripSectionRichText(
                    line.text,
                    _lineStyle,
                    onLink: (url) {
                      final l10n = AppLocalizations.of(context)!;
                      AmaterasuLinkOpener.openWebLink(
                        context,
                        url,
                        invalidMessage: l10n.commonLinkInvalid,
                        failedMessage: l10n.commonLinkOpenFailed,
                        copyLabel: l10n.commonLinkCopy,
                      );
                    },
                  ),
                )
              : Text(line.text, style: _lineStyle),
        ),
      ],
    ),
  );
}
