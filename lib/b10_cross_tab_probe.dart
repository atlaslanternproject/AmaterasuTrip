import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';

import 'core/security/pending_recovery_device_lock.dart';
import 'core/security/pending_recovery_device_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: B10CrossTabProbe(),
    ),
  );
}

class B10CrossTabProbe extends StatefulWidget {
  const B10CrossTabProbe({super.key});

  @override
  State<B10CrossTabProbe> createState() => _B10CrossTabProbeState();
}

class _B10CrossTabProbeState extends State<B10CrossTabProbe> {
  static const testUid =
      'amaterasu_b10_4_test_56baa09778134e3ebec5481c4d16a606';

  final _storage = PendingRecoveryDeviceStorage();

  bool _busy = false;
  String _status = 'Pronto. Identita di test nuova.';

  void _show(String message) {
    debugPrint('AMATERASU B10.4: $message');
    if (mounted) {
      setState(() => _status = message);
    }
  }

  Future<void> _hold() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      await withPendingRecoveryDeviceLock<void>(testUid, () async {
        _show(
          'HOLD_ACQUIRED\n'
          'Lock ottenuto.\n'
          'Ora prepara l identita nelle altre due schede.',
        );

        await Future<void>.delayed(const Duration(seconds: 25));
      });

      _show(
        'HOLD_RELEASED\n'
        'Lock rilasciato dopo 25 secondi.',
      );
    } catch (error) {
      _show('HOLD_ERROR: ${error.runtimeType}');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _prepare() async {
    if (_busy) return;
    setState(() => _busy = true);

    final start = DateTime.now().millisecondsSinceEpoch;
    _show(
      'PREPARING\n'
      'Richiesta in corso. In attesa del lock...',
    );

    try {
      final identity = await _storage.prepare(testUid);
      final restored = await PendingRecoveryDeviceStorage().read(testUid);

      if (restored == null || restored.deviceId != identity.deviceId) {
        throw StateError('Identity persistence mismatch.');
      }

      final hash = await Sha256().hash([
        ...utf8.encode(restored.deviceId),
        ...restored.exchangePublic,
        ...restored.signingPublic,
      ]);

      final fingerprint = hash.bytes
          .take(8)
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();

      final elapsed = DateTime.now().millisecondsSinceEpoch - start;

      _show(
        'PREPARE_OK\n'
        'Fingerprint: $fingerprint\n'
        'Attesa: $elapsed ms',
      );
    } catch (error) {
      _show('PREPARE_ERROR: ${error.runtimeType}');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Amaterasu B10.4 - Cross Tab')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_clock_outlined, size: 60),
                const SizedBox(height: 24),
                Text(_status, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _hold,
                  child: const Text('Blocca preparazione per 25 secondi'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : _prepare,
                  child: const Text('Prepara identita di test'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Test con UID fittizio. '
                  'Nessuna connessione Firebase. '
                  'Non modifica le identita reali.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
