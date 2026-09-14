import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/profile/models/user_profile.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class ProfileEditCard extends StatelessWidget {
  const ProfileEditCard({
    super.key,
    required this.profile,
    required this.isSaving,
    required this.firstNameController,
    required this.lastNameController,
    required this.bioController,
    required this.onChangeUsername,
  });

  static const Color _cardColor = Color(0xFF1A1512);
  static const Color _fieldColor = Color(0xFF14100E);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);

  final UserProfile profile;
  final bool isSaving;

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController bioController;

  final VoidCallback onChangeUsername;

  InputDecoration _decoration({required String label, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _subtitleColor),
      filled: true,
      fillColor: _fieldColor,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accentColor, width: 1.4),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.profileUsername,
            style: const TextStyle(color: _subtitleColor, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.username,
                  style: const TextStyle(
                    color: _titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: isSaving ? null : onChangeUsername,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.profileChangeUsername),
                style: TextButton.styleFrom(foregroundColor: _accentColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: firstNameController,
            enabled: !isSaving,
            textCapitalization: TextCapitalization.words,
            cursorColor: _accentColor,
            style: const TextStyle(color: _titleColor),
            decoration: _decoration(label: l10n.profileFirstName),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: lastNameController,
            enabled: !isSaving,
            textCapitalization: TextCapitalization.words,
            cursorColor: _accentColor,
            style: const TextStyle(color: _titleColor),
            decoration: _decoration(label: l10n.profileLastName),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: TextEditingController(text: profile.email ?? ''),
            enabled: false,
            style: const TextStyle(color: _subtitleColor),
            decoration: _decoration(
              label: l10n.profileEmail,
              suffixIcon: const Icon(
                Icons.lock_outline,
                color: _subtitleColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.profileEmailReadOnly,
            style: const TextStyle(color: _subtitleColor, fontSize: 12),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: bioController,
            enabled: !isSaving,
            maxLength: 200,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            cursorColor: _accentColor,
            style: const TextStyle(color: _titleColor),
            decoration: _decoration(label: l10n.profileBioHint),
          ),
        ],
      ),
    );
  }
}
