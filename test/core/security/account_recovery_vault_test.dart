import 'dart:convert';

import 'package:amaterasutrip/core/security/account_recovery_vault.dart';
import 'package:test/test.dart';

void main() {
  const uid = 'account-test-001';
  final root = List.filled(43, 'A').join();
  final otherRoot = List.filled(43, 'B').join();

  late AccountRecoveryVault vault;
  late List<int> recoverySecret;
  late List<int> portableDataKey;
  late AccountRecoveryEnvelope envelope;

  setUp(() async {
    vault = AccountRecoveryVault();
    recoverySecret = await vault.generateLocalSecret();
    portableDataKey = await vault.generateLocalSecret();

    envelope = await vault.seal(
      recoverySecret: recoverySecret,
      portableDataKey: portableDataKey,
      userUid: uid,
      rootFingerprint: root,
      revision: 1,
    );
  });

  Future<List<int>> recover({
    AccountRecoveryEnvelope? packet,
    List<int>? secret,
    String? expectedUid,
    String? expectedRoot,
    int revision = 1,
  }) {
    return vault.open(
      envelope: packet ?? envelope,
      recoverySecret: secret ?? recoverySecret,
      expectedUserUid: expectedUid ?? uid,
      expectedRootFingerprint: expectedRoot ?? root,
      expectedRevision: revision,
    );
  }

  test('Recupera la chiave portatile originale', () async {
    expect(await recover(), orderedEquals(portableDataKey));
  });

  test('Recupera con una nuova istanza del servizio', () async {
    final another = AccountRecoveryVault();

    final recovered = await another.open(
      envelope: envelope,
      recoverySecret: recoverySecret,
      expectedUserUid: uid,
      expectedRootFingerprint: root,
      expectedRevision: 1,
    );

    expect(recovered, orderedEquals(portableDataKey));
  });

  test('Envelope serializzabile e ripristinabile', () async {
    final json = jsonEncode(envelope.toMap());
    final restored = AccountRecoveryEnvelope.fromMap(
      Map<String, dynamic>.from(jsonDecode(json) as Map),
    );

    expect(await recover(packet: restored), orderedEquals(portableDataKey));
  });

  test('Il pacchetto non contiene chiavi in chiaro', () {
    final serialized = jsonEncode(envelope.toMap());

    expect(serialized, isNot(contains(base64Encode(recoverySecret))));
    expect(serialized, isNot(contains(base64Encode(portableDataKey))));
  });

  test('Un segreto di recupero errato viene rifiutato', () async {
    final wrongSecret = await vault.generateLocalSecret();

    await expectLater(recover(secret: wrongSecret), throwsA(anything));
  });

  test('Un altro account viene rifiutato', () async {
    await expectLater(
      recover(expectedUid: 'another-account'),
      throwsA(isA<StateError>()),
    );
  });

  test('Una radice di fiducia diversa viene rifiutata', () async {
    await expectLater(
      recover(expectedRoot: otherRoot),
      throwsA(isA<StateError>()),
    );
  });

  test('Una revisione differente viene rifiutata', () async {
    await expectLater(recover(revision: 2), throwsA(isA<StateError>()));
  });

  test('Il ciphertext modificato non viene decifrato', () async {
    final modified = base64Decode(envelope.ciphertext);
    modified[0] ^= 1;

    final corrupted = AccountRecoveryEnvelope(
      userUid: envelope.userUid,
      rootFingerprint: envelope.rootFingerprint,
      revision: envelope.revision,
      salt: envelope.salt,
      nonce: envelope.nonce,
      ciphertext: base64Encode(modified),
      mac: envelope.mac,
    );

    await expectLater(recover(packet: corrupted), throwsA(anything));
  });

  test('La modifica del tag di autenticazione viene rilevata', () async {
    final modified = base64Decode(envelope.mac);
    modified[0] ^= 1;

    final corrupted = AccountRecoveryEnvelope(
      userUid: envelope.userUid,
      rootFingerprint: envelope.rootFingerprint,
      revision: envelope.revision,
      salt: envelope.salt,
      nonce: envelope.nonce,
      ciphertext: envelope.ciphertext,
      mac: base64Encode(modified),
    );

    await expectLater(recover(packet: corrupted), throwsA(anything));
  });

  test('Due backup usano salt e nonce differenti', () async {
    final another = await vault.seal(
      recoverySecret: recoverySecret,
      portableDataKey: portableDataKey,
      userUid: uid,
      rootFingerprint: root,
      revision: 1,
    );

    expect(another.salt, isNot(envelope.salt));
    expect(another.nonce, isNot(envelope.nonce));
  });

  test('Versioni di pacchetto sconosciute sono rifiutate', () {
    final malformed = Map<String, dynamic>.from(envelope.toMap());
    malformed['version'] = 99;

    expect(
      () => AccountRecoveryEnvelope.fromMap(malformed),
      throwsFormatException,
    );
  });

  test('Lunghezze di pacchetto invalide sono rifiutate', () async {
    final malformed = AccountRecoveryEnvelope(
      userUid: envelope.userUid,
      rootFingerprint: envelope.rootFingerprint,
      revision: envelope.revision,
      salt: base64Encode([1, 2, 3]),
      nonce: envelope.nonce,
      ciphertext: envelope.ciphertext,
      mac: envelope.mac,
    );

    await expectLater(recover(packet: malformed), throwsFormatException);
  });
}
