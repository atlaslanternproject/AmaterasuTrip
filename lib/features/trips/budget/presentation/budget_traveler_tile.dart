import 'package:flutter/material.dart';

import 'budget_traveler_avatar.dart';

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
    const cream = Color(0xFFF2E7D5);
    const muted = Color(0xFFB7A99B);

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
                    : const Color(0xFF49352A),
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
                  activeColor: const Color(0xFFE17A43),
                  checkColor: const Color(0xFF100C0A),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
