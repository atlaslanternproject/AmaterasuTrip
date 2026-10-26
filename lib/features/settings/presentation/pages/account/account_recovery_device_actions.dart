import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/security/first_root_bootstrap_service.dart';
import 'package:amaterasutrip/core/security/recovery_device_preflight_service.dart';
import 'package:amaterasutrip/core/security/recovery_device_readiness_gate.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class AccountRecoveryDeviceActions extends StatefulWidget {
  const AccountRecoveryDeviceActions({super.key});

  @override
  State<AccountRecoveryDeviceActions> createState() =>
      _AccountRecoveryDeviceActionsState();
}

class _AccountRecoveryDeviceActionsState
    extends State<AccountRecoveryDeviceActions> {
  final _service = RecoveryDevicePreflightService();
  final _gate = const RecoveryDeviceReadinessGate();

  FirstRootState? _state;

  bool _busy = true;
  bool _failed = false;
  bool _pendingReady = false;
  bool _codeVerified = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    setState(() {
      _busy = true;
      _failed = false;
      _codeVerified = false;
      _pendingReady = false;
      _state = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final state = await _service.inspect();

      final pending = _gate.canPrepare(state)
          ? await _service.readPending()
          : null;

      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }

      setState(() {
        _state = state;
        _pendingReady = pending != null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _pendingReady = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _prepare() async {
    if (_busy || _state == null || !_gate.canPrepare(_state!)) {
      return;
    }

    setState(() => _busy = true);

    try {
      await _service.preparePending();

      if (mounted) {
        setState(() => _pendingReady = true);
      }
    } catch (_) {
      _showError();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showError() {
    if (!mounted) return;

    final l = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.accountRecoveryPreflightError)));
  }

  Future<void> _verify() async {
    if (_busy || _state == null || !_gate.canVerifyRecovery(_state!)) {
      return;
    }

    final l = AppLocalizations.of(context)!;

    String enteredCode = '';

    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.accountRecoveryPreflightDialog),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.accountRecoveryPreflightHelp),
              const SizedBox(height: 14),
              TextField(
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
                keyboardType: TextInputType.visiblePassword,
                onChanged: (value) => enteredCode = value,
                decoration: InputDecoration(
                  labelText: l.accountRecoveryPreflightInput,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.accountRecoveryPreflightCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(enteredCode),
            child: Text(l.accountRecoveryPreflightVerify),
          ),
        ],
      ),
    );

    if (!mounted || code == null) return;

    setState(() {
      _busy = true;
      _codeVerified = false;
    });

    try {
      await _service.enrolRecoveredDevice(code);

      if (mounted) {
        setState(() => _codeVerified = true);
      }
    } catch (_) {
      _showError();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _status(AppLocalizations l) {
    if (_failed) {
      return l.accountRecoveryPreflightUnavailable;
    }

    return switch (_state) {
      FirstRootState.setupAvailable => l.accountRootAvailable,
      FirstRootState.activeOnThisDevice => l.accountRootActive,
      FirstRootState.approvalOrRecoveryRequired => l.accountRootRecoveryNeeded,
      FirstRootState.blocked => l.accountRootBlocked,
      FirstRootState.verificationRequired => l.accountRootVerify,
      null => l.accountRootChecking,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    final l = AppLocalizations.of(context)!;

    final canRecover = !_failed && _state != null && _gate.canPrepare(_state!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF211A16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF74502C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.accountRecoveryPreflightTitle,
            style: const TextStyle(
              color: Color(0xFFF2E7D5),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _status(l),
            style: const TextStyle(color: Color(0xFFE2D1BD), height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            l.accountRecoveryPreflightDescription,
            style: const TextStyle(
              color: Color(0xFFBFAE9B),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (_pendingReady && canRecover) ...[
            const SizedBox(height: 12),
            Text(
              l.accountRecoveryPreflightPending,
              style: const TextStyle(color: Color(0xFFE7A044)),
            ),
          ],
          if (_codeVerified) ...[
            const SizedBox(height: 12),
            Text(
              l.accountRecoveryPreflightVerified,
              style: const TextStyle(color: Color(0xFFE7A044)),
            ),
          ],
          const SizedBox(height: 14),
          if (_busy)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (canRecover && !_pendingReady)
              FilledButton.icon(
                onPressed: _prepare,
                icon: const Icon(Icons.devices_outlined),
                label: Text(l.accountRecoveryPreflightPrepare),
              ),
            if (canRecover && _pendingReady)
              OutlinedButton.icon(
                onPressed: _verify,
                icon: const Icon(Icons.key_outlined),
                label: Text(l.accountRecoveryPreflightVerify),
              ),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: Text(l.accountRootRefresh),
            ),
          ],
        ],
      ),
    );
  }
}
