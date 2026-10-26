import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProbeApp());
}

class ProbeApp extends StatelessWidget {
  const ProbeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProbePage(),
    );
  }
}

class ProbePage extends StatefulWidget {
  const ProbePage({super.key});

  @override
  State<ProbePage> createState() => _ProbePageState();
}

class _ProbePageState extends State<ProbePage> {
  static const _key = 'b10_probe_identity_20261017';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      storageNamespace: 'amaterasu_b10_probe_20261017',
      resetOnError: false,
    ),
    webOptions: WebOptions(
      dbName: 'AmaterasuB10Probe20261017',
      publicKey: 'AmaterasuB10ProbeKey20261017',
      useSessionStorage: false,
    ),
  );

  final _ed25519 = Ed25519();

  String _status = 'Verifica iniziale...';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _inspect();
  }

  Future<void> _inspect() async {
    if (!mounted) return;

    setState(() {
      _busy = true;
    });

    try {
      final raw = await _storage.read(key: _key);

      if (raw == null) {
        if (mounted) {
          setState(() {
            _status =
                'NOT_FOUND\n'
                'Nessuna identita di TEST presente.\n'
                'Puoi crearne una.';
          });
        }
        return;
      }

      final decoded = jsonDecode(raw);

      if (decoded is! Map<String, dynamic> ||
          decoded['version'] != 1 ||
          decoded['private'] is! String ||
          decoded['public'] is! String) {
        throw const FormatException('Invalid test record.');
      }

      final privateBytes = base64Decode(decoded['private'] as String);
      final publicBytes = base64Decode(decoded['public'] as String);

      if (privateBytes.length != 32 || publicBytes.length != 32) {
        throw const FormatException('Invalid test key length.');
      }

      final publicKey = SimplePublicKey(publicBytes, type: KeyPairType.ed25519);

      final pair = SimpleKeyPairData(
        privateBytes,
        publicKey: publicKey,
        type: KeyPairType.ed25519,
      );

      final challenge = utf8.encode('amaterasu-b10-persistence-proof');

      final signature = await _ed25519.sign(challenge, keyPair: pair);

      final valid = await _ed25519.verify(
        challenge,
        signature: Signature(signature.bytes, publicKey: publicKey),
      );

      pair.destroy();

      if (!valid) {
        throw const FormatException('Invalid signing identity.');
      }

      final digest = await Sha256().hash(publicBytes);
      final fingerprint = digest.bytes
          .take(8)
          .map((v) => v.toRadixString(16).padLeft(2, '0'))
          .join();

      debugPrint(
        'AMATERASU B10 PROBE: IDENTITY_EXISTS_OK '
        'fingerprint=$fingerprint',
      );

      if (mounted) {
        setState(() {
          _status =
              'IDENTITY_EXISTS_OK\n'
              'Firma verificata.\n'
              'Fingerprint: $fingerprint\n'
              'Controlla che rimanga identico al riavvio.';
        });
      }
    } catch (_) {
      debugPrint('AMATERASU B10 PROBE: READ_ERROR');

      if (mounted) {
        setState(() {
          _status =
              'READ_ERROR\n'
              'Impossibile leggere o verificare '
              'la chiave di TEST.\n'
              'Non verra rigenerata automaticamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _create() async {
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    try {
      if (await _storage.read(key: _key) != null) {
        throw StateError('Test identity already exists.');
      }

      final pair = await _ed25519.newKeyPair();

      final privateBytes = await pair.extractPrivateKeyBytes();
      final publicKey = await pair.extractPublicKey();

      await _storage.write(
        key: _key,
        value: jsonEncode({
          'version': 1,
          'private': base64Encode(privateBytes),
          'public': base64Encode(publicKey.bytes),
        }),
      );

      pair.destroy();

      debugPrint('AMATERASU B10 PROBE: TEST_CREATED');

      if (mounted) {
        setState(() {
          _status =
              'TEST_CREATED\n'
              'Identita di prova salvata.\n'
              'Premi Verifica per controllarla.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _status =
              'CREATE_ERROR\n'
              'Creazione non riuscita oppure '
              'identita gia presente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Amaterasu B10 - Test locale')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, size: 56),
                const SizedBox(height: 20),
                Text(_status, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _inspect,
                  child: const Text('Verifica chiave di test'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : _create,
                  child: const Text('Crea chiave di test'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Archivio separato. Nessuna operazione '
                  'su Firebase o sulle chiavi E2EE reali.',
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
