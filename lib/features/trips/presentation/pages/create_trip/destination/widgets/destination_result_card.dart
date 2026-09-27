import 'package:flutter/material.dart';

class DestinationResultCard extends StatelessWidget {
  const DestinationResultCard({
    super.key,
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String flag;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  static const Color _surfaceColor = Color(0xFF1A1715);
  static const Color _selectedSurfaceColor = Color(0xFF211611);
  static const Color _borderColor = Color(0xFF332824);
  static const Color _selectedBorderColor = Color(0xFF9E452C);
  static const Color _creamColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);
  static const Color _accentColor = Color(0xFFF07845);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? _selectedSurfaceColor : _surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? _selectedBorderColor : _borderColor,
              width: isSelected ? 1.2 : 1,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x262F0B00),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF120E0C),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF653322) : _borderColor,
                  ),
                ),
                child: Text(flag, style: const TextStyle(fontSize: 25)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _creamColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? _accentColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? _accentColor
                        : _secondaryTextColor.withValues(alpha: 0.45),
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF160C08),
                        size: 17,
                        weight: 700,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
