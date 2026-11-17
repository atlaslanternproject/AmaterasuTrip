import 'package:flutter/material.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

class TripDestinationField extends StatelessWidget {
  const TripDestinationField({
    super.key,
    required this.label,
    required this.hint,
    required this.destination,
    required this.onTap,
  });

  final String label;
  final String hint;
  final String? destination;
  final VoidCallback onTap;

  static const Color _surfaceColor = AmaterasuColors.surfaceNeutral;
  static const Color _borderColor = AmaterasuColors.surfaceHigh;
  static const Color _creamColor = AmaterasuColors.textPrimary;
  static const Color _secondaryTextColor = AmaterasuColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final hasDestination =
        destination != null && destination!.trim().isNotEmpty;

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
              const Icon(
                Icons.location_on_outlined,
                color: _creamColor,
                size: 24,
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
                      hasDestination ? destination! : hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasDestination
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
