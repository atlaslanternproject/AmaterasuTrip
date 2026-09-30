import 'package:flutter/material.dart';

class TripCloudSelector extends StatelessWidget {
  const TripCloudSelector({
    super.key,
    required this.sectionLabel,
    required this.title,
    required this.subtitle,
    required this.configuredLabel,
    required this.onTap,
    this.selectedProvider,
  });

  final String sectionLabel;
  final String title;
  final String subtitle;
  final String configuredLabel;
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
                      ? _accentColor.withValues(alpha: 0.75)
                      : _borderColor,
                  width: hasProvider ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hasProvider
                          ? _accentColor.withValues(alpha: 0.16)
                          : const Color(0xFF241B17),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      hasProvider
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_outlined,
                      color: hasProvider ? _accentColor : _creamColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasProvider) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: _accentColor,
                                  size: 14,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  configuredLabel,
                                  style: const TextStyle(
                                    color: _accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 7),
                        ],
                        Text(
                          hasProvider ? selectedProvider! : title,
                          style: TextStyle(
                            color: _creamColor,
                            fontSize: hasProvider ? 16 : 15,
                            fontWeight: hasProvider
                                ? FontWeight.w700
                                : FontWeight.w600,
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
                  Icon(
                    hasProvider
                        ? Icons.edit_outlined
                        : Icons.chevron_right_rounded,
                    color: hasProvider ? _accentColor : _secondaryTextColor,
                    size: hasProvider ? 20 : 24,
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
