import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:amaterasutrip/core/security/android_pending_device_enrollment.dart';
import 'package:amaterasutrip/core/security/device_approval_exchange.dart';
import 'package:amaterasutrip/core/security/device_enrollment_request.dart';
import 'package:amaterasutrip/core/security/local_trust_pin_status.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'e2ee_qr_scanner_page.dart';

class AccountE2eeDevicePage extends StatelessWidget {
  const AccountE2eeDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF100C0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF100C0A),
        title: Text(l10n.accountE2eeDeviceTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: const [AccountE2eeDeviceContent()],
      ),
    );
  }
}

class _DeviceRequestPreviewCache {
  static String? _uid;
  static DeviceEnrollmentRequest? _snapshot;
  static bool _ready = false;
  static Future<DeviceEnrollmentRequest?>? _inFlight;
  static int _generation = 0;

  static Future<DeviceEnrollmentRequest?> read({required String uid}) {
    if (_uid != uid) {
      _uid = uid;
      _snapshot = null;
      _ready = false;
      _inFlight = null;
      _generation++;
    }

    if (_ready) {
      final cached = _snapshot;

      if (cached != null &&
          DateTime.now().toUtc().millisecondsSinceEpoch >= cached.expiresAtMs) {
        _snapshot = null;
        return Future.value(null);
      }

      return Future.value(cached);
    }

    final running = _inFlight;
    if (running != null) return running;

    final generation = ++_generation;

    final future = AndroidPendingDeviceEnrollment()
        .readSavedApprovalRequest(uid: uid)
        .then((request) {
          if (_uid == uid && generation == _generation) {
            _snapshot = request;
            _ready = true;
          }

          return request;
        })
        .whenComplete(() {
          if (_uid == uid && generation == _generation) {
            _inFlight = null;
          }
        });

    _inFlight = future;
    return future;
  }

  static void remember(String uid, DeviceEnrollmentRequest request) {
    _uid = uid;
    _generation++;
    _snapshot = request;
    _ready = true;
    _inFlight = null;
  }

  static void markExpired(String uid) {
    if (_uid != uid) return;

    _generation++;
    _snapshot = null;
    _ready = true;
    _inFlight = null;
  }
}

class AccountE2eeDeviceContent extends StatefulWidget {
  const AccountE2eeDeviceContent({super.key});

  static void prefetchPreview() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !user.emailVerified) return;

    unawaited(
      _DeviceRequestPreviewCache.read(
        uid: user.uid,
      ).then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    );
  }

  @override
  State<AccountE2eeDeviceContent> createState() =>
      _AccountE2eeDeviceContentState();
}

class _AccountE2eeDeviceContentState extends State<AccountE2eeDeviceContent> {
  static const _gold = Color(0xFFE7A044);
  static const _cream = Color(0xFFF2E7D5);
  static const _edge = Color(0xFF493223);

  bool _busy = false;
  bool _expired = false;
  bool _checkingRequest = false;

  String? _publicRequest;
  int? _expiresAtMs;

  late final Future<LocalTrustPinStatus> _pinStatus;

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser?.uid;

    _pinStatus = uid == null
        ? Future.value(LocalTrustPinStatus.unavailable)
        : LocalTrustPinStatusService().forUser(uid);

    _checkingRequest = _android;

    // Render the first frame before reading and checking stored
    // cryptographic identity material.
    // The integrity checks remain mandatory.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _android) {
        Future<void>.delayed(const Duration(milliseconds: 80), () {
          if (mounted) _restore();
        });
      }
    });
  }

  Future<void> _restore() async {
    final diagnostic = Stopwatch()..start();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !user.emailVerified) {
      if (mounted) {
        setState(() => _checkingRequest = false);
      }
      return;
    }

    try {
      final enrollment = AndroidPendingDeviceEnrollment();

      final saved = await _DeviceRequestPreviewCache.read(uid: user.uid);

      if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) {
        return;
      }

      if (saved != null) {
        _showRequest(saved);
      } else {
        final wasExpired = await enrollment.hasExpiredSavedRequest(
          uid: user.uid,
        );

        if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) {
          return;
        }

        if (wasExpired) {
          setState(() => _expired = true);
        }
      }
    } catch (_) {
      // Fail closed: never replace unverified device keys.
    } finally {
      if (kDebugMode) {
        debugPrint(
          'Device security request check: '
          '${diagnostic.elapsedMilliseconds} ms',
        );
      }
      if (mounted) {
        setState(() => _checkingRequest = false);
      }
    }
  }

  void _showRequest(DeviceEnrollmentRequest request) {
    if (!mounted) return;

    setState(() {
      _publicRequest = request.toQrPayload();
      _expiresAtMs = request.expiresAtMs;
      _expired = false;
    });
  }

  void _onExpired() {
    if (!mounted || _expired) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      _DeviceRequestPreviewCache.markExpired(uid);
    }

    setState(() {
      _expired = true;
      _publicRequest = null;
      _expiresAtMs = null;
    });
  }

  Future<void> _notice(String body) async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountE2eeQrResultTitle),
        content: Text(body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.accountE2eeQrContinue),
          ),
        ],
      ),
    );
  }

  Future<void> _prepare() async {
    if (_busy || _checkingRequest || !_android) return;

    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !user.emailVerified) {
      await _notice(l10n.accountE2eeDeviceError);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountE2eeDeviceConsentTitle),
        content: Text(l10n.accountE2eeDeviceConsentText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.accountE2eeQrContinue),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() => _busy = true);

    // Allow the progress indicator to paint before key operations.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    try {
      final request = await AndroidPendingDeviceEnrollment()
          .prepareApprovalRequest(uid: user.uid, userConfirmed: true);

      if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) {
        return;
      }

      _DeviceRequestPreviewCache.remember(user.uid, request);
      _showRequest(request);
    } catch (_) {
      if (mounted) {
        await _notice(l10n.accountE2eeDeviceError);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _scan() async {
    if (_busy || !_android) return;

    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !user.emailVerified) {
      await _notice(l10n.accountE2eeDeviceError);
      return;
    }

    final consent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountE2eeQrCameraTitle),
        content: Text(l10n.accountE2eeQrCameraText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.accountE2eeQrContinue),
          ),
        ],
      ),
    );

    if (!mounted || consent != true) return;

    final payload = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const E2eeQrScannerPage()),
    );

    if (!mounted || payload == null) return;

    try {
      if (payload.startsWith(DeviceEnrollmentRequest.qrPrefix)) {
        final request = DeviceEnrollmentRequest.fromQrPayload(
          payload,
          expectedUserUid: user.uid,
          nowUtc: DateTime.now().toUtc(),
        );

        final mine = _publicRequest;

        if (mine != null && mine == request.toQrPayload()) {
          await _notice(l10n.accountE2eeQrSelfScan);
          return;
        }
      } else if (payload.startsWith(DeviceApprovalExchange.prefix)) {
        final response = DeviceApprovalExchange().decodeUntrusted(payload);

        if (response.claim.userUid != user.uid) {
          throw const FormatException('Different account');
        }

        // Parsing is NOT signature verification.
        // No access, trust or private keys are granted here.
      } else {
        throw const FormatException('Unknown code');
      }

      await _notice(l10n.accountE2eeQrReadOnly);
    } catch (_) {
      await _notice(l10n.accountE2eeQrInvalid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF211A16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _edge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.phonelink_lock_outlined,
                    color: _gold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.accountE2eeDeviceTitle,
                      style: const TextStyle(
                        color: _cream,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _android
                    ? l10n.accountE2eeDeviceExplanation
                    : l10n.accountE2eeDeviceUnavailable,
                style: const TextStyle(
                  color: Color(0xFFC4B5A5),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              FutureBuilder<LocalTrustPinStatus>(
                future: _pinStatus,
                builder: (context, snapshot) {
                  final status =
                      snapshot.connectionState == ConnectionState.waiting
                      ? l10n.accountE2eePinChecking
                      : switch (snapshot.data) {
                          LocalTrustPinStatus.present =>
                            l10n.accountE2eePinPresent,
                          LocalTrustPinStatus.missing =>
                            l10n.accountE2eePinMissing,
                          _ => l10n.accountE2eePinUnavailable,
                        };

                  return Text(
                    status,
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              if (_android) ...[
                if (_checkingRequest)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF33251C),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6A472B)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE7A044),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.accountE2eePinChecking,
                            style: const TextStyle(
                              color: Color(0xFFF2E7D5),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_expired) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A211C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFDB6152)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer_off_outlined,
                          color: Color(0xFFFFA092),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.accountE2eeQrExpired,
                            style: const TextStyle(color: _cream),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (_publicRequest == null)
                  FilledButton.icon(
                    onPressed: (_busy || _checkingRequest) ? null : _prepare,
                    icon: (_busy || _checkingRequest)
                        ? const SizedBox(
                            height: 19,
                            width: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFF2E7D5),
                            ),
                          )
                        : const Icon(Icons.verified_user_outlined),
                    label: Text(
                      _expired
                          ? l10n.accountE2eeQrRegenerate
                          : l10n.accountE2eeDevicePrepare,
                    ),
                  ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(22),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_publicRequest != null && _expiresAtMs != null) ...[
                  Text(
                    l10n.accountE2eeDevicePending,
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 345),
                      decoration: BoxDecoration(
                        color: const Color(0xFF281914),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFC7853A),
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x332B1006),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(12, 13, 12, 11),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.wb_sunny_rounded,
                                  size: 27,
                                  color: Color(0xFFF1AE50),
                                ),
                                SizedBox(width: 9),
                                Text(
                                  'AMATERASU',
                                  style: TextStyle(
                                    color: Color(0xFFF4DEBB),
                                    fontSize: 13,
                                    letterSpacing: 2.4,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 11),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0D7),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: QrImageView(
                              key: ValueKey(_publicRequest),
                              data: _publicRequest!,
                              size: (MediaQuery.sizeOf(context).width - 145)
                                  .clamp(175.0, 296.0)
                                  .toDouble(),
                              padding: EdgeInsets.zero,
                              gapless: true,
                              backgroundColor: const Color(0xFFFFF0D7),
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.circle,
                                color: Color(0xFF743016),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.circle,
                                color: Color(0xFF351F17),
                              ),
                              version: QrVersions.auto,
                              errorCorrectionLevel: QrErrorCorrectLevel.L,
                              errorStateBuilder: (context, error) =>
                                  Text(l10n.accountE2eeDeviceError),
                            ),
                          ),
                          const SizedBox(height: 11),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _QrCountdown(
                    key: ValueKey(_expiresAtMs),
                    expiryMs: _expiresAtMs!,
                    onExpired: _onExpired,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.accountE2eeQrPendingHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFC4B5A5),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                OutlinedButton.icon(
                  onPressed: _busy ? null : _scan,
                  icon: const Icon(Icons.qr_code_scanner_outlined),
                  label: Text(l10n.accountE2eeQrScan),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF30231B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _edge),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: _gold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.accountE2eeQrWebNotice,
                          style: const TextStyle(color: _cream, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrCountdown extends StatefulWidget {
  const _QrCountdown({
    super.key,
    required this.expiryMs,
    required this.onExpired,
  });

  final int expiryMs;
  final VoidCallback onExpired;

  @override
  State<_QrCountdown> createState() => _QrCountdownState();
}

class _QrCountdownState extends State<_QrCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  void _tick() {
    if (!mounted) return;

    if (DateTime.now().millisecondsSinceEpoch >= widget.expiryMs) {
      _timer?.cancel();
      widget.onExpired();
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left =
        ((widget.expiryMs - DateTime.now().millisecondsSinceEpoch + 999) ~/
                1000)
            .clamp(0, 86400);

    final minutes = (left ~/ 60).toString().padLeft(2, '0');
    final seconds = (left % 60).toString().padLeft(2, '0');

    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.timer_outlined, color: Color(0xFFE7A044), size: 18),
        const SizedBox(width: 8),
        Text(
          '${l10n.accountE2eeQrRemaining} $minutes:$seconds',
          style: const TextStyle(
            color: Color(0xFFF2E7D5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
