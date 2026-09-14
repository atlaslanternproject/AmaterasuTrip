import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_unsaved_changes_dialog.dart';
import 'package:amaterasutrip/features/profile/models/user_profile.dart';
import 'package:amaterasutrip/features/profile/providers/user_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import 'profile_photo_source_sheet.dart';
import 'profile_username_dialog.dart';
import 'widgets/profile_edit_card.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_view_card.dart';

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

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  bool _allowPop = false;

  String _originalFirstName = '';
  String _originalLastName = '';
  String _originalBio = '';

  String? _draftProfileUid;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();

    super.dispose();
  }

  void _prepareDraft(UserProfile profile, {bool force = false}) {
    if (!force && _draftProfileUid == profile.uid) {
      return;
    }

    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _bioController.text = profile.bio ?? '';

    _originalFirstName = profile.firstName?.trim() ?? '';
    _originalLastName = profile.lastName?.trim() ?? '';
    _originalBio = profile.bio?.trim() ?? '';

    _draftProfileUid = profile.uid;
  }

  void _startEditing(UserProfile profile) {
    _prepareDraft(profile, force: true);

    setState(() {
      _isEditing = true;
    });
  }

  bool get _hasUnsavedChanges {
    if (!_isEditing) {
      return false;
    }

    return _firstNameController.text.trim() != _originalFirstName ||
        _lastNameController.text.trim() != _originalLastName ||
        _bioController.text.trim() != _originalBio;
  }

  Future<bool> _saveProfile({required bool exitAfterSave}) async {
    if (_isSaving) {
      return false;
    }

    final l10n = AppLocalizations.of(context)!;

    if (_bioController.text.trim().length > 200) {
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
        bio: _bioController.text,
      );

      if (!mounted) {
        return false;
      }

      _originalFirstName = _firstNameController.text.trim();
      _originalLastName = _lastNameController.text.trim();
      _originalBio = _bioController.text.trim();

      if (exitAfterSave) {
        setState(() {
          _isSaving = false;
          _isEditing = false;
          _allowPop = true;
        });

        Navigator.of(context).pop();

        return true;
      }

      setState(() {
        _isSaving = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileSaveSuccess)));

      return true;
    } catch (_) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileSaveError)));

      return false;
    }
  }

  Future<void> _handleAttemptToLeave() async {
    if (_allowPop) {
      return;
    }

    if (!_hasUnsavedChanges) {
      setState(() {
        _allowPop = true;
      });

      Navigator.of(context).pop();
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
        return;

      case AmaterasuUnsavedChangesAction.saveAndExit:
        await _saveProfile(exitAfterSave: true);
        return;

      case AmaterasuUnsavedChangesAction.cancel:
        return;
    }
  }

  Future<void> _changeUsername(UserProfile profile) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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

  Future<void> _changeProfilePhoto(UserProfile profile) async {
    final l10n = AppLocalizations.of(context)!;

    final action = await showProfilePhotoSourceSheet(
      context: context,
      hasCustomPhoto:
          profile.photoUrl != null && profile.photoUrl!.trim().isNotEmpty,
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == ProfilePhotoSourceAction.remove) {
      // La rimozione reale verrà collegata a Firebase Storage
      // nel prossimo step.
      return;
    }

    final picker = ref.read(profilePhotoPickerServiceProvider);

    try {
      XFile? selectedPhoto;

      switch (action) {
        case ProfilePhotoSourceAction.camera:
          selectedPhoto = await picker.pickFromCamera();
          break;

        case ProfilePhotoSourceAction.gallery:
          selectedPhoto = await picker.pickFromGallery();
          break;

        case ProfilePhotoSourceAction.remove:
          return;
      }

      if (!mounted || selectedPhoto == null) {
        return;
      }

      debugPrint('Selected profile photo: ${selectedPhoto.path}');
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profilePhotoPickerError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final profileAsync = ref.watch(currentUserProfileProvider);

    return PopScope(
      canPop: _allowPop,
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
          foregroundColor: _titleColor,
          surfaceTintColor: Colors.transparent,
          title: Text(l10n.settingsProfile),
          actions: [
            profileAsync.maybeWhen(
              data: (profile) {
                if (profile == null) {
                  return const SizedBox.shrink();
                }

                if (_isEditing) {
                  return IconButton(
                    tooltip: l10n.profileSave,
                    onPressed: _isSaving
                        ? null
                        : () {
                            _saveProfile(exitAfterSave: false);
                          },
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _accentColor,
                            ),
                          )
                        : const Icon(Icons.check, color: _accentColor),
                  );
                }

                return IconButton(
                  tooltip: l10n.profileEditTitle,
                  onPressed: () {
                    _startEditing(profile);
                  },
                  icon: const Icon(Icons.edit_outlined, color: _accentColor),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        body: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _accentColor),
          ),
          error: (_, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.profileSaveError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _subtitleColor),
              ),
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return Center(
                child: Text(
                  l10n.profileSaveError,
                  style: const TextStyle(color: _subtitleColor),
                ),
              );
            }

            if (!_isEditing) {
              _prepareDraft(profile);
            }

            return _ProfileContent(
              profile: profile,
              isEditing: _isEditing,
              isSaving: _isSaving,
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              bioController: _bioController,
              onChangeUsername: () {
                _changeUsername(profile);
              },
              onChangePhoto: () {
                _changeProfilePhoto(profile);
              },
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
    required this.onChangeUsername,
    required this.onChangePhoto,
  });

  final UserProfile profile;
  final bool isEditing;
  final bool isSaving;

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController bioController;

  final VoidCallback onChangeUsername;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        ProfileHeader(
          profile: profile,
          onChangePhoto: onChangePhoto,
        ),
        const SizedBox(height: 24),
        if (isEditing)
          ProfileEditCard(
            profile: profile,
            isSaving: isSaving,
            firstNameController: firstNameController,
            lastNameController: lastNameController,
            bioController: bioController,
            onChangeUsername: onChangeUsername,
          )
        else
          ProfileViewCard(profile: profile),
      ],
    );
  }
}