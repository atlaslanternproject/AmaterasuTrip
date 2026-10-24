import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

import 'package:amaterasutrip/core/security/first_device_trust_anchor.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    throw ArgumentError('One output path is required.');
  }

  // Ephemeral identities generated only for this test.
  final exchange = await X25519().newKeyPair();
  final signing = await Ed25519().newKeyPair();

  final exchangePublic = await exchange.extractPublicKey();
  final signingPublic = await signing.extractPublicKey();

  const uid = 'amaterasu-interop-test';

  final deviceId = base64UrlEncode(
    List<int>.generate(32, (i) => i),
  ).replaceAll('=', '');

  final anchor = FirstDeviceTrustAnchor(
    userUid: uid,
    deviceId: deviceId,
    x25519PublicKey: exchangePublic.bytes,
    ed25519PublicKey: signingPublic.bytes,
    createdAtMs: DateTime.now().toUtc().millisecondsSinceEpoch,
  );

  final anchorService = FirstDeviceTrustAnchorService();

  final signed = await anchorService.issue(
    anchor: anchor,
    localSigningKey: signing,
  );

  final fingerprint = await anchorService.fingerprint(anchor);

  await anchorService.verifyPinned(
    signed: signed,
    expectedUserUid: uid,
    expectedDeviceId: deviceId,
    pinnedFingerprint: fingerprint,
  );

  // Only test data, not an actual recovery backup.
  // Exact envelope shape needed to exercise the server validator.
  final root = <String, dynamic>{
    'version': 1,
    'userUid': uid,
    'deviceId': deviceId,
    'createdAtMs': anchor.createdAtMs,
    'x25519PublicKey': base64Encode(anchor.x25519PublicKey),
    'ed25519PublicKey': base64Encode(anchor.ed25519PublicKey),
    'signature': base64Encode(signed.signatureBytes),
    'fingerprint': fingerprint,
    'recovery': <String, dynamic>{
      'version': 1,
      'salt': base64Encode(List<int>.filled(32, 2)),
      'nonce': base64Encode(List<int>.filled(12, 3)),
      'ciphertext': base64Encode(List<int>.filled(64, 4)),
      'mac': base64Encode(List<int>.filled(16, 5)),
    },
  };

  // No private key or recovery secret is serialized.
  await File(args.single).writeAsString(jsonEncode(root), flush: true);

  stdout.writeln('SYNTHETIC_DART_ROOT_CREATED');
}
