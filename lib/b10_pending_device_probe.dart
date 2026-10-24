import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';

import 'core/security/pending_recovery_device_identity.dart';
import 'core/security/pending_recovery_device_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: B10PendingDeviceProbe(),
    ),
  );
}

class B10PendingDeviceProbe extends StatefulWidget {
  const B10PendingDeviceProbe({super.key});

  @override
  State<B10PendingDeviceProbe> createState() => _B10PendingDeviceProbeState();
}

class _B10PendingDeviceProbeState extends State<B10PendingDeviceProbe> {
  // NON e' un account Firebase reale.
  static const testUid = 'amaterasu_b10_2_fake_uid_20261017';

  // Usa ESATTAMENTE il costruttore reale del modulo B10.
  final PendingRecoveryDeviceStorage storage = PendingRecoveryDeviceStorage();

  bool busy = false;
  String result = 'Controllo archivio locale...';

  @override
  void initState() {
    super.initState();

    // All'avvio SOLO LETTURA.
    // Nessuna generazione automatica.
    _check(prepare: false);
  }

  Future<String> _fingerprint(PendingRecoveryDeviceIdentity identity) async {
    final digest = await Sha256().hash([
      ...utf8.encode(identity.deviceId),
      ...identity.exchangePublic,
      ...identity.signingPublic,
    ]);

    return digest.bytes
        .take(8)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Future<void> _verifySignature(PendingRecoveryDeviceIdentity identity) async {
    final ed = Ed25519();

    final pair = await ed.newKeyPairFromSeed(identity.signingPrivate);

    final publicKey = SimplePublicKey(
      identity.signingPublic,
      type: KeyPairType.ed25519,
    );

    final challenge = utf8.encode('amaterasu-b10-2-local-verification');

    final signature = await ed.sign(challenge, keyPair: pair);

    final valid = await ed.verify(
      challenge,
      signature: Signature(signature.bytes, publicKey: publicKey),
    );

    pair.destroy();

    if (!valid) {
      throw StateError('Stored signing key is invalid.');
    }
  }

  Future<void> _check({required bool prepare}) async {
    if (busy) return;

    setState(() {
      busy = true;
    });

    try {
      final before = await storage.read(testUid);

      // prepare() viene chiamato SOLO dal pulsante.
      final identity = prepare ? await storage.prepare(testUid) : before;

      if (identity == null) {
        debugPrint('AMATERASU B10.2: NOT_FOUND');

        if (mounted) {
          setState(() {
            result =
                'NOT_FOUND\n\n'
                'Nessuna identita di test presente.\n'
                'Nessuna chiave generata automaticamente.';
          });
        }
        return;
      }

      if (before != null && before.deviceId != identity.deviceId) {
        throw StateError('An existing device identity was replaced.');
      }

      // Seconda lettura da una nuova istanza del modulo.
      final reopened = await PendingRecoveryDeviceStorage().read(testUid);

      if (reopened == null ||
          reopened.deviceId != identity.deviceId ||
          reopened.uid != testUid) {
        throw StateError('Stored device identity changed.');
      }

      // decodeLocal() ha gia' verificato le coppie
      // X25519 ed Ed25519. Proviamo anche una firma.
      await _verifySignature(reopened);

      final fingerprint = await _fingerprint(reopened);

      final outcome = prepare ? 'PREPARE_OK' : 'READ_OK';

      debugPrint(
        'AMATERASU B10.2: $outcome '
        'fingerprint=$fingerprint',
      );

      if (mounted) {
        setState(() {
          result =
              '$outcome\n\n'
              'Identita verificata.\n'
              'Chiavi X25519 ed Ed25519 coerenti.\n'
              'Firma Ed25519 valida.\n\n'
              'Fingerprint:\n$fingerprint\n\n'
              'Confrontalo dopo il riavvio.';
        });
      }
    } catch (error) {
      debugPrint(
        'AMATERASU B10.2: ERROR '
        '(${error.runtimeType})',
      );

      if (mounted) {
        setState(() {
          result =
              'ERROR\n\n'
              'Lettura, persistenza o verifica fallita.\n'
              'Non sono state rigenerate chiavi '
              'automaticamente.\n\n'
              'Tipo: ${error.runtimeType}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Amaterasu B10.2')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_outlined, size: 64),
                const SizedBox(height: 24),
                Text(result, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : () => _check(prepare: false),
                  child: const Text('Verifica identita salvata'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: busy ? null : () => _check(prepare: true),
                  child: const Text('Prepara identita di test'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'UID fittizio. Nessun Firebase, '
                  'nessuna approvazione del dispositivo '
                  'e nessuna modifica alle chiavi reali.',
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
