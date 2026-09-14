import 'package:flutter/material.dart';

class AmaterasuSettingsCard extends StatelessWidget {
  const AmaterasuSettingsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isExpanded = false,
    this.children = const [],
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isExpanded;
  final List<Widget> children;
  final bool enabled;

  static const Color _cardColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);
  static const Color _chevronColor = Color(0xFFB89B7A);

  static const Color _disabledCardColor = Color(0xFF171412);
  static const Color _disabledBorderColor = Color(0xFF2B2724);
  static const Color _disabledIconColor = Color(0xFF6D6761);
  static const Color _disabledTitleColor = Color(0xFF77716B);
  static const Color _disabledSubtitleColor = Color(0xFF5F5A55);
  static const Color _disabledChevronColor = Color(0xFF5F5A55);

  @override
  Widget build(BuildContext context) {
    final effectiveCardColor = enabled ? _cardColor : _disabledCardColor;

    final effectiveBorderColor = enabled ? _borderColor : _disabledBorderColor;

    final effectiveIconColor = enabled ? _accentColor : _disabledIconColor;

    final effectiveTitleColor = enabled ? _titleColor : _disabledTitleColor;

    final effectiveSubtitleColor = enabled
        ? _subtitleColor
        : _disabledSubtitleColor;

    final effectiveChevronColor = enabled
        ? _chevronColor
        : _disabledChevronColor;

    final showExpandedContent = enabled && isExpanded && children.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: effectiveCardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: effectiveBorderColor, width: 1),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: effectiveIconColor.withValues(
                              alpha: enabled ? 0.75 : 0.45,
                            ),
                          ),
                        ),
                        child: Icon(icon, color: effectiveIconColor, size: 23),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: effectiveTitleColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: effectiveSubtitleColor,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        enabled && isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.chevron_right,
                        color: effectiveChevronColor,
                        size: 24,
                      ),
                    ],
                  ),
                ),
                if (showExpandedContent)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(children: _withSpacing(children)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> widgets) {
    final result = <Widget>[];

    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);

      if (i < widgets.length - 1) {
        result.add(const SizedBox(height: 8));
      }
    }

    return result;
  }
}
