import 'package:flutter/material.dart';

class TripCloudSelector extends StatelessWidget {
  const TripCloudSelector({
    super.key,
    required this.sectionLabel,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selectedProvider,
  });

  final String sectionLabel;
  final String title;
  final String subtitle;
  final String? selectedProvider;
  final VoidCallback onTap;

  static const Color _surfaceColor = Color(0xFF1A1715);
  static const Color _borderColor = Color(0xFF332824);
  static const Color _creamColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);
  static const Color _accentColor = Color(0xFFD96C32);

  @override
  Widget build(BuildContext context) {
    final hasProvider =
        selectedProvider != null && selectedProvider!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 9),
          child: Text(
            sectionLabel,
            style: const TextStyle(
              color: _secondaryTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: hasProvider
                      ? _accentColor.withValues(alpha: 0.55)
                      : _borderColor,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hasProvider
                          ? _accentColor.withValues(alpha: 0.12)
                          : const Color(0xFF241B17),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      hasProvider
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_outlined,
                      color: hasProvider ? _accentColor : _creamColor,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasProvider ? selectedProvider! : title,
                          style: const TextStyle(
                            color: _creamColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: _secondaryTextColor,
                            fontSize: 12,
                            height: 1.35,
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
        ),
      ],
    );
  }
}
