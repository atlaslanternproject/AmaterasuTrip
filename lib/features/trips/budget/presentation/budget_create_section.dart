import 'package:flutter/material.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

class BudgetCreateSection extends StatelessWidget {
  const BudgetCreateSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    this.accent = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> children;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    const cream = AmaterasuColors.textPrimary;
    const muted = AmaterasuColors.textSecondary;
    const gold = AmaterasuColors.accentGold;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFF34241D) : const Color(0xFF2B201B),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: accent ? const Color(0xFF9A5936) : AmaterasuColors.borderStrong,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF402C23),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: gold, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: cream,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
