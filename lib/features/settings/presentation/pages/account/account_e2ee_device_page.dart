import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amaterasutrip/core/security/android_pending_device_enrollment.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class AccountE2eeDevicePage extends StatefulWidget {
  const AccountE2eeDevicePage({super.key});

  @override
  State<AccountE2eeDevicePage> createState() => _AccountE2eeDevicePageState();
}

class _AccountE2eeDevicePageState extends State<AccountE2eeDevicePage> {
  bool _busy = false;
  String? _publicRequest;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _prepare() async {
    if (_busy || !_supported) return;

    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !user.emailVerified) {
      _message(l10n.accountE2eeDeviceError);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountE2eeDeviceConsentTitle),
        content: Text(l10n.accountE2eeDeviceConsentText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.accountE2eeDevicePrepare),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() => _busy = true);

    try {
      final request = await AndroidPendingDeviceEnrollment()
          .prepareApprovalRequest(uid: user.uid, userConfirmed: true);

      if (!mounted) return;

      setState(() {
        _publicRequest = request.toQrPayload();
      });
    } catch (_) {
      if (!mounted) return;

      // Do not expose internal errors, keys or private data in UI/logs.
      _message(l10n.accountE2eeDeviceError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _copyRequest() async {
    final value = _publicRequest;

    if (value == null) return;

    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) return;

    _message(AppLocalizations.of(context)!.accountE2eeDeviceCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    const cream = Color(0xFFF2E7D5);
    const gold = Color(0xFFE6AD58);

    return Scaffold(
      backgroundColor: const Color(0xFF100C0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF100C0A),
        foregroundColor: cream,
        title: Text(l10n.accountE2eeDeviceTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.shield_outlined, color: gold, size: 50),
          const SizedBox(height: 20),
          Text(
            l10n.accountE2eeDeviceExplanation,
            style: const TextStyle(color: cream, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 20),
          if (!_supported)
            Text(
              l10n.accountE2eeDeviceUnavailable,
              style: const TextStyle(color: gold),
            )
          else
            FilledButton.icon(
              onPressed: _busy ? null : _prepare,
              icon: const Icon(Icons.phonelink_lock_outlined),
              label: Text(l10n.accountE2eeDevicePrepare),
            ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_publicRequest != null) ...[
            const SizedBox(height: 24),
            Text(
              l10n.accountE2eeDevicePending,
              style: const TextStyle(color: gold, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF211A16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                _publicRequest!,
                style: const TextStyle(color: cream, fontSize: 11),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _copyRequest,
              icon: const Icon(Icons.copy_outlined),
              label: Text(l10n.accountE2eeDeviceCopy),
            ),
          ],
        ],
      ),
    );
  }
}
