import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/security/first_root_bootstrap_service.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class FirstDeviceBootstrapCard extends StatefulWidget {
  const FirstDeviceBootstrapCard({super.key});

  @override
  State<FirstDeviceBootstrapCard> createState() =>
      _FirstDeviceBootstrapCardState();
}

class _FirstDeviceBootstrapCardState extends State<FirstDeviceBootstrapCard> {
  final _service = FirstRootBootstrapService();

  FirstRootState? _state;
  bool _busy = true;
  bool _error = false;

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
      _error = false;
    });

    try {
      final result = await _service.inspect();

      if (mounted) {
        setState(() => _state = result);
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _notice(String message) async {
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.accountRootTitle),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.accountRootClose),
          ),
        ],
      ),
    );
  }

  Future<void> _activate() async {
    if (_busy || _state != FirstRootState.setupAvailable) {
      return;
    }

    final l = AppLocalizations.of(context)!;
    setState(() => _busy = true);

    try {
      final prepared = await _service.prepare();
      if (!mounted) return;

      var saved = false;

      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, updateDialog) => AlertDialog(
            title: Text(l.accountRootRecoveryTitle),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 510),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.accountRootRecoveryWarning),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0D7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SelectableText(
                        prepared.recoveryCode,
                        style: const TextStyle(
                          color: Color(0xFF342019),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: saved,
                      onChanged: (value) {
                        updateDialog(() => saved = value ?? false);
                      },
                      title: Text(l.accountRootRecoveryConfirm),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l.accountRootCancel),
              ),
              FilledButton(
                onPressed: saved
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                child: Text(l.accountRootActivate),
              ),
            ],
          ),
        ),
      );

      if (accepted != true || !mounted) return;

      await _service.activate(prepared);

      if (!mounted) return;
      await _notice(l.accountRootActivated);
    } catch (_) {
      if (mounted) {
        await _notice(l.accountRootError);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    final String status;

    if (_error) {
      status = l.accountRootError;
    } else {
      status = switch (_state) {
        FirstRootState.setupAvailable => l.accountRootAvailable,
        FirstRootState.activeOnThisDevice => l.accountRootActive,
        FirstRootState.approvalOrRecoveryRequired =>
          l.accountRootRecoveryNeeded,
        FirstRootState.blocked => l.accountRootBlocked,
        FirstRootState.verificationRequired => l.accountRootVerify,
        null => l.accountRootChecking,
      };
    }

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
          Row(
            children: [
              const Icon(Icons.security_rounded, color: Color(0xFFE7A044)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.accountRootTitle,
                  style: const TextStyle(
                    color: Color(0xFFF2E7D5),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            status,
            style: const TextStyle(color: Color(0xFFE2D1BD), height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            l.accountRootExperimental,
            style: const TextStyle(
              color: Color(0xFFE7A044),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          if (_busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(color: Color(0xFFE7A044)),
              ),
            )
          else if (!_error && _state == FirstRootState.setupAvailable)
            FilledButton.icon(
              onPressed: _activate,
              icon: const Icon(Icons.verified_user_outlined),
              label: Text(l.accountRootActivate),
            )
          else
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: Text(l.accountRootRefresh),
            ),
        ],
      ),
    );
  }
}
