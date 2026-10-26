import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/account_recovery_kit.dart';
import 'package:amaterasutrip/core/security/account_recovery_vault.dart';
import 'package:amaterasutrip/core/security/first_device_trust_anchor.dart';
import 'package:amaterasutrip/core/security/first_root_recovery_codec.dart';
import 'package:amaterasutrip/core/security/first_root_recovery_record.dart';

class RecoveryFixture {
  RecoveryFixture(
    this.signed,
    this.code,
    this.envelope,
    this.uid,
    this.fingerprint,
  );

  final SignedFirstDeviceTrustAnchor signed;
  final String code;
  final Map<String, dynamic> envelope;
  final String uid;
  final String fingerprint;
}

Future<RecoveryFixture> makeFixture() async {
  const uid = 'audit-root-user';

  final exchange = await X25519().newKeyPair();
  final signing = await Ed25519().newKeyPair();

  final anchor = FirstDeviceTrustAnchor(
    userUid: uid,
    deviceId: 'audit-original-device',
    x25519PublicKey: (await exchange.extractPublicKey()).bytes,
    ed25519PublicKey: (await signing.extractPublicKey()).bytes,
    createdAtMs: 1700000000000,
  );

  final anchorService = FirstDeviceTrustAnchorService();

  final signed = await anchorService.issue(
    anchor: anchor,
    localSigningKey: signing,
  );

  final fingerprint = await anchorService.fingerprint(anchor);
  final secret = await AccountRecoveryVault().generateLocalSecret();

  final code = await AccountRecoveryKitCodec().encode(
    userUid: uid,
    rootFingerprint: fingerprint,
    recoverySecret: secret,
  );

  final aes = AesGcm.with256bits();
  final salt = await (await aes.newSecretKey()).extractBytes();

  final context = utf8.encode(
    jsonEncode([
      'amaterasutrip',
      'first-root-private-backup',
      1,
      uid,
      fingerprint,
    ]),
  );

  final key = await Hkdf(
    hmac: Hmac.sha256(),
    outputLength: 32,
  ).deriveKey(secretKey: SecretKey(secret), nonce: salt, info: context);

  final encrypted = await aes.encrypt(
    [
      ...await exchange.extractPrivateKeyBytes(),
      ...await signing.extractPrivateKeyBytes(),
    ],
    secretKey: key,
    nonce: aes.newNonce(),
    aad: context,
  );

  return RecoveryFixture(
    signed,
    code,
    {
      'version': 1,
      'salt': base64Encode(salt),
      'nonce': base64Encode(encrypted.nonce),
      'ciphertext': base64Encode(encrypted.cipherText),
      'mac': base64Encode(encrypted.mac.bytes),
    },
    uid,
    fingerprint,
  );
}

void main() {
  group('Recovery Proof 3H.5A', () {
    test('01 - Codice corretto recupera entrambe le chiavi', () async {
      final f = await makeFixture();

      await FirstRootRecoveryCodec().verify(
        recoveryCode: f.code,
        expectedUserUid: f.uid,
        signed: f.signed,
        envelope: f.envelope,
      );
    });

    test('02 - Segreto di recupero errato rifiutato', () async {
      final f = await makeFixture();

      final wrongCode = await AccountRecoveryKitCodec().encode(
        userUid: f.uid,
        rootFingerprint: f.fingerprint,
        recoverySecret: await AccountRecoveryVault().generateLocalSecret(),
      );

      await expectLater(
        FirstRootRecoveryCodec().verify(
          recoveryCode: wrongCode,
          expectedUserUid: f.uid,
          signed: f.signed,
          envelope: f.envelope,
        ),
        throwsA(isA<Object>()),
      );
    });

    test('03 - Ciphertext manomesso rifiutato', () async {
      final f = await makeFixture();
      final altered = Map<String, dynamic>.from(f.envelope);

      final bytes = base64Decode(altered['ciphertext'] as String);
      bytes[0] ^= 1;
      altered['ciphertext'] = base64Encode(bytes);

      await expectLater(
        FirstRootRecoveryCodec().verify(
          recoveryCode: f.code,
          expectedUserUid: f.uid,
          signed: f.signed,
          envelope: altered,
        ),
        throwsA(isA<Object>()),
      );
    });

    test('04 - Account differente rifiutato', () async {
      final f = await makeFixture();

      await expectLater(
        FirstRootRecoveryCodec().verify(
          recoveryCode: f.code,
          expectedUserUid: 'different-account',
          signed: f.signed,
          envelope: f.envelope,
        ),
        throwsA(isA<Object>()),
      );
    });

    test('05 - Identita firmata sostituita rifiutata', () async {
      final f = await makeFixture();

      final exchange = await X25519().newKeyPair();
      final signing = await Ed25519().newKeyPair();

      final replacement = FirstDeviceTrustAnchor(
        userUid: f.uid,
        deviceId: 'replacement-device',
        x25519PublicKey: (await exchange.extractPublicKey()).bytes,
        ed25519PublicKey: (await signing.extractPublicKey()).bytes,
        createdAtMs: 1700000000001,
      );

      final signedReplacement = await FirstDeviceTrustAnchorService().issue(
        anchor: replacement,
        localSigningKey: signing,
      );

      await expectLater(
        FirstRootRecoveryCodec().verify(
          recoveryCode: f.code,
          expectedUserUid: f.uid,
          signed: signedReplacement,
          envelope: f.envelope,
        ),
        throwsA(isA<Object>()),
      );
    });

    test('06 - Backup incompleto rifiutato', () async {
      final f = await makeFixture();
      final altered = Map<String, dynamic>.from(f.envelope);
      altered.remove('mac');

      await expectLater(
        FirstRootRecoveryCodec().verify(
          recoveryCode: f.code,
          expectedUserUid: f.uid,
          signed: f.signed,
          envelope: altered,
        ),
        throwsA(isA<FormatException>()),
      );
    });
    test('07 - Recovered key material matches signed root', () async {
      final f = await makeFixture();

      final recovered = await FirstRootRecoveryCodec().recover(
        recoveryCode: f.code,
        expectedUserUid: f.uid,
        signed: f.signed,
        envelope: f.envelope,
      );

      expect(recovered.uid, f.uid);
      expect(recovered.deviceId, f.signed.anchor.deviceId);
      expect(recovered.createdAtMs, f.signed.anchor.createdAtMs);
      expect(recovered.exchangePrivate, hasLength(32));
      expect(recovered.signingPrivate, hasLength(32));

      final exchange = await X25519().newKeyPairFromSeed(
        recovered.exchangePrivate,
      );
      final signing = await Ed25519().newKeyPairFromSeed(
        recovered.signingPrivate,
      );

      expect(
        (await exchange.extractPublicKey()).bytes,
        f.signed.anchor.x25519PublicKey,
      );
      expect(
        (await signing.extractPublicKey()).bytes,
        f.signed.anchor.ed25519PublicKey,
      );
    });

    test('08 - Wrong recovery secret cannot return private keys', () async {
      final f = await makeFixture();

      final incorrect = await AccountRecoveryKitCodec().encode(
        userUid: f.uid,
        rootFingerprint: f.fingerprint,
        recoverySecret: await AccountRecoveryVault().generateLocalSecret(),
      );

      await expectLater(
        FirstRootRecoveryCodec().recover(
          recoveryCode: incorrect,
          expectedUserUid: f.uid,
          signed: f.signed,
          envelope: f.envelope,
        ),
        throwsA(isA<Object>()),
      );
    });
    test('09 - Server record and recovery code restore key material', () async {
      final f = await makeFixture();
      final anchor = f.signed.anchor;

      final remote = <String, dynamic>{
        'version': 1,
        'userUid': f.uid,
        'deviceId': anchor.deviceId,
        'createdAtMs': anchor.createdAtMs,
        'x25519PublicKey': base64Encode(anchor.x25519PublicKey),
        'ed25519PublicKey': base64Encode(anchor.ed25519PublicKey),
        'signature': base64Encode(f.signed.signatureBytes),
        'fingerprint': f.fingerprint,
        'recovery': f.envelope,
      };

      final record = FirstRootRecoveryRecord.fromServer(
        uid: f.uid,
        data: remote,
      );

      final recovered = await record.recover(f.code);

      expect(recovered.uid, f.uid);
      expect(recovered.exchangePrivate, hasLength(32));
      expect(recovered.signingPrivate, hasLength(32));
    });

    test('10 - Remote root fingerprint mismatch is rejected', () async {
      final f = await makeFixture();
      final anchor = f.signed.anchor;

      final remote = <String, dynamic>{
        'version': 1,
        'userUid': f.uid,
        'deviceId': anchor.deviceId,
        'createdAtMs': anchor.createdAtMs,
        'x25519PublicKey': base64Encode(anchor.x25519PublicKey),
        'ed25519PublicKey': base64Encode(anchor.ed25519PublicKey),
        'signature': base64Encode(f.signed.signatureBytes),
        'fingerprint': 'invalid-fingerprint',
        'recovery': f.envelope,
      };

      final record = FirstRootRecoveryRecord.fromServer(
        uid: f.uid,
        data: remote,
      );

      await expectLater(record.recover(f.code), throwsA(isA<StateError>()));
    });

    test('11 - Remote identity for another user is rejected', () async {
      final f = await makeFixture();

      expect(
        () => FirstRootRecoveryRecord.fromServer(
          uid: 'another-account',
          data: {
            'version': 1,
            'userUid': f.uid,
            'deviceId': f.signed.anchor.deviceId,
            'createdAtMs': f.signed.anchor.createdAtMs,
            'x25519PublicKey': base64Encode(f.signed.anchor.x25519PublicKey),
            'ed25519PublicKey': base64Encode(f.signed.anchor.ed25519PublicKey),
            'signature': base64Encode(f.signed.signatureBytes),
            'fingerprint': f.fingerprint,
            'recovery': f.envelope,
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
