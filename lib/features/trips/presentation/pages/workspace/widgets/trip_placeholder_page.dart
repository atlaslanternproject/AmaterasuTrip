// Pagina segnaposto comune per le sezioni del workspace non ancora sviluppate.

import 'package:flutter/material.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';

class TripPlaceholderPage extends StatelessWidget {
  const TripPlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    required this.tripId,
    this.bottomNavigationBar,
    this.onBack,
  });

  final String title;
  final IconData icon;
  final String tripId;
  final Widget? bottomNavigationBar;
  final VoidCallback? onBack;

  static const Color _backgroundColor = AmaterasuColors.surfaceDeep;
  static const Color _surfaceColor = AmaterasuColors.surfaceWarm;
  static const Color _borderColor = AmaterasuColors.borderAccent;
  static const Color _accentColor = AmaterasuColors.accentBudget;
  static const Color _titleColor = AmaterasuColors.textPrimary;
  static const Color _secondaryTextColor = AmaterasuColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(width: AmaterasuSpacing.xs),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _titleColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AmaterasuSpacing.lg),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 36,
                    ),
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _borderColor.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _accentColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(icon, color: _accentColor, size: 32),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _titleColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AmaterasuSpacing.sm),
                        Text(
                          tripId,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
