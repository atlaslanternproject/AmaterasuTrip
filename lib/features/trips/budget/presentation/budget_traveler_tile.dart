import 'package:flutter/material.dart';

import 'budget_traveler_avatar.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

class BudgetTravelerTile extends StatelessWidget {
  const BudgetTravelerTile({
    super.key,
    required this.name,
    required this.selected,
    required this.enabled,
    required this.onChanged,
    this.photoUrl,
  });

  final String name;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    const cream = AmaterasuColors.textPrimary;
    const muted = AmaterasuColors.textSecondary;

    final displayName = name.trim().isEmpty ? '—' : name.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: selected ? const Color(0xFF473127) : const Color(0xFF271C18),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? () => onChanged(!selected) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFFAA7049)
                    : AmaterasuColors.borderStrong,
              ),
            ),
            child: Row(
              children: [
                BudgetTravelerAvatar(
                  name: displayName,
                  photoUrl: photoUrl,
                  size: 34,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      color: enabled ? cream : muted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Checkbox(
                  value: selected,
                  onChanged: enabled
                      ? (value) => onChanged(value ?? false)
                      : null,
                  activeColor: AmaterasuColors.accentOrange,
                  checkColor: AmaterasuColors.surfaceDeep,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
