import 'package:flutter/material.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

class TripCurrencySelector extends StatelessWidget {
  const TripCurrencySelector({
    super.key,
    required this.label,
    required this.hint,
    required this.currency,
    required this.onTap,
    this.symbol,
  });

  final String label;
  final String hint;
  final String? currency;
  final String? symbol;
  final VoidCallback onTap;

  static const Color _surfaceColor = AmaterasuColors.surfaceNeutral;
  static const Color _borderColor = AmaterasuColors.surfaceHigh;
  static const Color _creamColor = AmaterasuColors.textPrimary;
  static const Color _secondaryTextColor = AmaterasuColors.textSecondary;
  static const Color _accentColor = AmaterasuColors.accentFlame;

  @override
  Widget build(BuildContext context) {
    final hasCurrency = currency != null && currency!.trim().isNotEmpty;
    final hasSymbol = symbol != null && symbol!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AmaterasuColors.surfaceRaisedAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: hasCurrency && hasSymbol
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(
                            symbol!,
                            style: const TextStyle(
                              color: _accentColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.currency_exchange_rounded,
                        color: _creamColor,
                        size: 21,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasCurrency ? currency! : hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasCurrency
                            ? _creamColor
                            : _secondaryTextColor.withValues(alpha: 0.55),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: _secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
