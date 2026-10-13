import 'dart:async';
import 'dart:js_interop';

import 'package:amaterasutrip/core/security/first_device_trust_anchor.dart';
import 'package:amaterasutrip/core/security/web_first_device_trust_pin_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

Future<void> deleteDatabase(String name) async {
  final request = web.window.indexedDB.deleteDatabase(name);
  final completed = Completer<void>();

  request.onsuccess = ((JSAny? _) {
    if (!completed.isCompleted) completed.complete();
  }).toJS;

  request.onerror = ((JSAny? _) {
    if (!completed.isCompleted) {
      completed.completeError(StateError('Test DB cleanup failed.'));
    }
  }).toJS;

  // onblocked may be temporary while a transaction finishes.
  // Wait for onsuccess/onerror; timeout detects a permanent block.

  await completed.future.timeout(const Duration(seconds: 20));
}

void main() {
  final anchors = FirstDeviceTrustAnchorService();
  final ed25519 = Ed25519();
  final x25519 = X25519();
  final timestamp = DateTime.utc(2026, 10, 13).millisecondsSinceEpoch;

  late SimpleKeyPair signer;
  late SimpleKeyPair attacker;
  late List<int> xPublic;
  late FirstDeviceTrustAnchor root;
  late SignedFirstDeviceTrustAnchor signedRoot;
  late String trustedPin;

  late String databaseName;
  late WebFirstDeviceTrustPinStorage store;
  var databaseCounter = 0;

  Future<void> pinRoot({SignedFirstDeviceTrustAnchor? signed, String? pin}) {
    return store.pinVerifiedRoot(
      signed: signed ?? signedRoot,
      independentlyTrustedFingerprint: pin ?? trustedPin,
    );
  }

  setUpAll(() async {
    signer = await ed25519.newKeyPair();
    attacker = await ed25519.newKeyPair();

    final signingPublic = await signer.extractPublicKey();
    xPublic = (await (await x25519.newKeyPair()).extractPublicKey()).bytes;

    root = FirstDeviceTrustAnchor(
      userUid: 'audit-user',
      deviceId: 'android-first',
      x25519PublicKey: xPublic,
      ed25519PublicKey: signingPublic.bytes,
      createdAtMs: timestamp,
    );

    signedRoot = await anchors.issue(anchor: root, localSigningKey: signer);

    // Locally established test trust anchor, never from Firebase.
    trustedPin = await anchors.fingerprint(root);
  });

  setUp(() async {
    databaseCounter++;

    databaseName =
        'amaterasu_pin_audit_${DateTime.now().microsecondsSinceEpoch}_$databaseCounter';

    store = await WebFirstDeviceTrustPinStorage.open(
      databaseName: databaseName,
    );
  });

  tearDown(() async {
    store.close();
    await deleteDatabase(databaseName);
  });

  test('Nessuna identita remota viene considerata attendibile', () async {
    final missing = await store.readPin(userUid: 'audit-user');
    expect(missing, isNull);
  });

  test('Salva e recupera una identita gia verificata', () async {
    await pinRoot();

    final restored = await store.readPin(userUid: 'audit-user');

    expect(restored, isNotNull);
    expect(restored!.deviceId, 'android-first');
    expect(restored.fingerprint, trustedPin);
  });

  test('Mantiene il pin dopo la riapertura del database', () async {
    await pinRoot();

    store.close();

    store = await WebFirstDeviceTrustPinStorage.open(
      databaseName: databaseName,
    );

    final restored = await store.readPin(userUid: 'audit-user');

    expect(restored?.fingerprint, trustedPin);
    expect(restored?.deviceId, 'android-first');
  });

  test('Blocca la sovrascrittura dello stesso account', () async {
    await pinRoot();

    await expectLater(pinRoot(), throwsStateError);

    final restored = await store.readPin(userUid: 'audit-user');
    expect(restored?.fingerprint, trustedPin);
  });

  test('Rifiuta identita sostitutiva auto-firmata', () async {
    await pinRoot();

    final attackerPublic = await attacker.extractPublicKey();

    final forgedRoot = FirstDeviceTrustAnchor(
      userUid: 'audit-user',
      deviceId: 'android-first',
      x25519PublicKey: xPublic,
      ed25519PublicKey: attackerPublic.bytes,
      createdAtMs: timestamp,
    );

    final forged = await anchors.issue(
      anchor: forgedRoot,
      localSigningKey: attacker,
    );

    final stored = await store.readPin(userUid: 'audit-user');

    await expectLater(
      store.pinVerifiedRoot(
        signed: forged,
        independentlyTrustedFingerprint: stored!.fingerprint,
      ),
      throwsStateError,
    );

    final unchanged = await store.readPin(userUid: 'audit-user');
    expect(unchanged?.fingerprint, trustedPin);
  });

  test('Scritture concorrenti: una sola riesce', () async {
    Future<bool> attempt() async {
      try {
        await pinRoot();
        return true;
      } catch (_) {
        return false;
      }
    }

    final outcomes = await Future.wait([attempt(), attempt()]);

    expect(outcomes.where((value) => value).length, 1);

    final stored = await store.readPin(userUid: 'audit-user');
    expect(stored?.fingerprint, trustedPin);
  });

  test('L identita di un altro account rimane separata', () async {
    await pinRoot();

    final other = await store.readPin(userUid: 'other-user');
    expect(other, isNull);
  });
}
