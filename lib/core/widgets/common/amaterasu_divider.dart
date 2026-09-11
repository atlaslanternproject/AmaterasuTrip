import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../../theme/Amaterasu_colors.dart';
class AmaterasuDivider extends StatelessWidget {
  final String? text;
  const AmaterasuDivider({
    super.key,
    this.text,
  });
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AmaterasuColors.border,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          child: Text(
            text ?? l10n.commonOr,
            style: const TextStyle(
              color: AmaterasuColors.white54,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: AmaterasuColors.border,
          ),
        ),
      ],
    );
  }
}