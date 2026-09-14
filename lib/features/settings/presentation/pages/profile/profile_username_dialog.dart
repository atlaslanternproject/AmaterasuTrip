import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

import 'package:amaterasutrip/features/profile/providers/user_provider.dart';

class ProfileUsernameDialog extends ConsumerStatefulWidget {
  const ProfileUsernameDialog({super.key, required this.currentUsername});

  final String currentUsername;

  @override
  ConsumerState<ProfileUsernameDialog> createState() =>
      _ProfileUsernameDialogState();
}

class _ProfileUsernameDialogState extends ConsumerState<ProfileUsernameDialog> {
  static const Color _backgroundColor = Color(0xFF1A1512);
  static const Color _fieldColor = Color(0xFF14100E);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);

  late final TextEditingController _usernameController;

  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    _usernameController = TextEditingController(text: widget.currentUsername);
  }

  @override
  void dispose() {
    _usernameController.dispose();

    super.dispose();
  }

  Future<void> _changeUsername() async {
    final l10n = AppLocalizations.of(context)!;
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _errorText = l10n.profileUsernameRequired;
      });

      return;
    }

    if (username == widget.currentUsername.trim()) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final repository = ref.read(userRepositoryProvider);

      await repository.updateUsername(username: username);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (error.code == 'username-already-in-use') {
          _errorText = l10n.profileUsernameAlreadyInUse;
        } else {
          _errorText = l10n.profileUsernameChangeError;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = l10n.profileUsernameChangeError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: _backgroundColor,
      surfaceTintColor: Colors.transparent,
      title: Text(
        l10n.profileChangeUsername,
        style: const TextStyle(color: _titleColor, fontWeight: FontWeight.w600),
      ),
      content: TextField(
        controller: _usernameController,
        enabled: !_isSaving,
        autofocus: true,
        textInputAction: TextInputAction.done,
        cursorColor: _accentColor,
        style: const TextStyle(color: _titleColor),
        onSubmitted: (_) {
          if (!_isSaving) {
            _changeUsername();
          }
        },
        decoration: InputDecoration(
          labelText: l10n.profileNewUsername,
          errorText: _errorText,
          labelStyle: const TextStyle(color: _subtitleColor),
          filled: true,
          fillColor: _fieldColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accentColor, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD66A5E)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD66A5E), width: 1.4),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: Text(
            l10n.unsavedChangesCancel,
            style: const TextStyle(color: _subtitleColor),
          ),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _changeUsername,
          style: FilledButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: const Color(0xFF100C0A),
          ),
          child: _isSaving
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF100C0A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.profileUsernameChanging),
                  ],
                )
              : Text(l10n.profileUsernameConfirm),
        ),
      ],
    );
  }
}
