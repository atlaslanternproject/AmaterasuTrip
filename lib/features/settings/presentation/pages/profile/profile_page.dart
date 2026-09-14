import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_unsaved_changes_dialog.dart';
import 'package:amaterasutrip/features/profile/models/user_profile.dart';
import 'package:amaterasutrip/features/profile/providers/user_provider.dart';

import 'profile_username_dialog.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);

  static const int _bioMaxLength = 200;

  final TextEditingController _firstNameController = TextEditingController();

  final TextEditingController _lastNameController = TextEditingController();

  final TextEditingController _bioController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  bool _allowPop = false;

  String _originalFirstName = '';
  String _originalLastName = '';
  String _originalBio = '';

  @override
  void initState() {
    super.initState();

    _firstNameController.addListener(_onDraftChanged);

    _lastNameController.addListener(_onDraftChanged);

    _bioController.addListener(_onDraftChanged);
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_onDraftChanged);

    _lastNameController.removeListener(_onDraftChanged);

    _bioController.removeListener(_onDraftChanged);

    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();

    super.dispose();
  }

  void _onDraftChanged() {
    if (_isEditing && mounted) {
      setState(() {});
    }
  }

  bool get _hasUnsavedChanges {
    if (!_isEditing) {
      return false;
    }

    return _firstNameController.text.trim() != _originalFirstName ||
        _lastNameController.text.trim() != _originalLastName ||
        _bioController.text.trim() != _originalBio;
  }

  void _startEditing(UserProfile profile) {
    _originalFirstName = profile.firstName?.trim() ?? '';

    _originalLastName = profile.lastName?.trim() ?? '';

    _originalBio = profile.bio?.trim() ?? '';

    _firstNameController.text = _originalFirstName;

    _lastNameController.text = _originalLastName;

    _bioController.text = _originalBio;

    setState(() {
      _isEditing = true;
      _allowPop = false;
    });
  }

  Future<bool> _saveProfile({required bool exitAfterSave}) async {
    final l10n = AppLocalizations.of(context)!;

    final bio = _bioController.text.trim();

    if (bio.length > _bioMaxLength) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileBioTooLong)));

      return false;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(userRepositoryProvider);

      await repository.updateProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        bio: bio,
      );

      if (!mounted) {
        return false;
      }

      _originalFirstName = _firstNameController.text.trim();

      _originalLastName = _lastNameController.text.trim();

      _originalBio = bio;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileSaveSuccess)));

      if (exitAfterSave) {
        _allowPop = true;

        Navigator.of(context).pop();

        return true;
      }

      setState(() {
        _isEditing = false;
      });

      return true;
    } catch (_) {
      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileSaveError)));

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleAttemptToLeave() async {
    if (_isSaving) {
      return;
    }

    final action = await showAmaterasuUnsavedChangesDialog(context);

    if (!mounted) {
      return;
    }

    switch (action) {
      case AmaterasuUnsavedChangesAction.discard:
        setState(() {
          _allowPop = true;
        });

        Navigator.of(context).pop();

      case AmaterasuUnsavedChangesAction.saveAndExit:
        await _saveProfile(exitAfterSave: true);

      case AmaterasuUnsavedChangesAction.cancel:
        return;
    }
  }

  Future<void> _changeUsername(UserProfile profile) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ProfileUsernameDialog(currentUsername: profile.username);
      },
    );

    if (!mounted || changed != true) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.profileUsernameChangeSuccess)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final profileAsync = ref.watch(currentUserProfileProvider);

    final canPopWithoutConfirmation = !_hasUnsavedChanges || _allowPop;

    return PopScope(
      canPop: canPopWithoutConfirmation,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        await _handleAttemptToLeave();
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: _backgroundColor,
          elevation: 0,
          title: Text(
            l10n.settingsProfile,
            style: const TextStyle(
              color: _titleColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            profileAsync.maybeWhen(
              data: (profile) {
                if (profile == null) {
                  return const SizedBox.shrink();
                }

                if (_isEditing) {
                  return IconButton(
                    onPressed: _isSaving || !_hasUnsavedChanges
                        ? null
                        : () {
                            _saveProfile(exitAfterSave: false);
                          },
                    tooltip: l10n.profileSave,
                    icon: const Icon(Icons.check),
                    color: _accentColor,
                    disabledColor: _subtitleColor,
                  );
                }

                return IconButton(
                  onPressed: () {
                    _startEditing(profile);
                  },
                  tooltip: l10n.profileEditTitle,
                  icon: const Icon(Icons.edit_outlined, color: _accentColor),
                );
              },
              orElse: () {
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return Center(
                child: Text(
                  l10n.settingsPlaceholder,
                  style: const TextStyle(color: _subtitleColor),
                ),
              );
            }

            return _ProfileContent(
              profile: profile,
              isEditing: _isEditing,
              isSaving: _isSaving,
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              bioController: _bioController,
              bioMaxLength: _bioMaxLength,
              onChangeUsername: () {
                _changeUsername(profile);
              },
            );
          },
          loading: () {
            return const Center(
              child: CircularProgressIndicator(color: _accentColor),
            );
          },
          error: (_, _) {
            return Center(
              child: Text(
                l10n.settingsPlaceholder,
                style: const TextStyle(color: _subtitleColor),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.isEditing,
    required this.isSaving,
    required this.firstNameController,
    required this.lastNameController,
    required this.bioController,
    required this.bioMaxLength,
    required this.onChangeUsername,
  });

  final UserProfile profile;
  final bool isEditing;
  final bool isSaving;

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController bioController;

  final int bioMaxLength;

  final VoidCallback onChangeUsername;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final fullName = [profile.firstName, profile.lastName]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        _ProfileHeader(username: profile.username, email: profile.email),
        const SizedBox(height: 16),
        if (isEditing)
          _ProfileEditCard(
            profile: profile,
            isSaving: isSaving,
            firstNameController: firstNameController,
            lastNameController: lastNameController,
            bioController: bioController,
            bioMaxLength: bioMaxLength,
            onChangeUsername: onChangeUsername,
          )
        else
          _ProfileInfoCard(
            children: [
              _ProfileInfoRow(
                icon: Icons.person_outline,
                label: l10n.profileUsername,
                value: profile.username,
              ),
              const _ProfileDivider(),
              _ProfileInfoRow(
                icon: Icons.badge_outlined,
                label: l10n.profileFullName,
                value: fullName.isEmpty ? '—' : fullName,
              ),
              const _ProfileDivider(),
              _ProfileInfoRow(
                icon: Icons.email_outlined,
                label: l10n.profileEmail,
                value: profile.email ?? '—',
              ),
              const _ProfileDivider(),
              _ProfileInfoRow(
                icon: Icons.notes_outlined,
                label: l10n.profileBio,
                value: profile.bio?.trim().isNotEmpty == true
                    ? profile.bio!.trim()
                    : '—',
              ),
            ],
          ),
      ],
    );
  }
}

class _ProfileEditCard extends StatelessWidget {
  const _ProfileEditCard({
    required this.profile,
    required this.isSaving,
    required this.firstNameController,
    required this.lastNameController,
    required this.bioController,
    required this.bioMaxLength,
    required this.onChangeUsername,
  });

  final UserProfile profile;
  final bool isSaving;

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController bioController;

  final int bioMaxLength;

  final VoidCallback onChangeUsername;

  static const Color _cardColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);
  static const Color _fieldColor = Color(0xFF14100E);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: _accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileUsername,
                      style: const TextStyle(
                        color: _subtitleColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.username,
                      style: const TextStyle(
                        color: _titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: isSaving ? null : onChangeUsername,
                child: Text(l10n.profileChangeUsername),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ProfileTextField(
            controller: firstNameController,
            label: l10n.profileFirstName,
            icon: Icons.badge_outlined,
            enabled: !isSaving,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          _ProfileTextField(
            controller: lastNameController,
            label: l10n.profileLastName,
            icon: Icons.badge_outlined,
            enabled: !isSaving,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _fieldColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.email_outlined, color: _subtitleColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileEmail,
                        style: const TextStyle(
                          color: _subtitleColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email ?? '—',
                        style: const TextStyle(
                          color: _titleColor,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.profileEmailReadOnly,
                        style: const TextStyle(
                          color: _subtitleColor,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.lock_outline, color: _subtitleColor, size: 19),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ProfileTextField(
            controller: bioController,
            label: l10n.profileBio,
            hint: l10n.profileBioHint,
            icon: Icons.notes_outlined,
            enabled: !isSaving,
            maxLines: 5,
            maxLength: bioMaxLength,
            textInputAction: TextInputAction.newline,
          ),
        ],
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.textInputAction,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final TextInputAction textInputAction;
  final String? hint;
  final int maxLines;
  final int? maxLength;

  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);
  static const Color _fieldColor = Color(0xFF14100E);
  static const Color _borderColor = Color(0xFF3A2A20);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      textInputAction: textInputAction,
      cursorColor: _accentColor,
      style: const TextStyle(color: _titleColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _subtitleColor),
        hintStyle: const TextStyle(color: _subtitleColor),
        prefixIcon: Icon(icon, color: _accentColor),
        filled: true,
        fillColor: _fieldColor,
        counterStyle: const TextStyle(color: _subtitleColor),
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
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.username, required this.email});

  final String username;
  final String? email;

  static const Color _cardColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _accentColor, width: 2),
            ),
            child: ClipOval(
              child: Transform.scale(
                scale: 1.33,
                alignment: const Alignment(0, 0.10),
                child: Image.asset(
                  'assets/images/profile/amaterasu_profile_fallback.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, 0.13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _subtitleColor, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.children});

  final List<Widget> children;

  static const Color _cardColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accentColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _subtitleColor, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _titleColor,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFF2A211C),
      indent: 16,
      endIndent: 16,
    );
  }
}
