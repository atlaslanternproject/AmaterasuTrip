import 'package:amaterasutrip/core/security/account_recovery_kit.dart';
import 'package:amaterasutrip/core/security/account_recovery_vault.dart';
import 'package:test/test.dart';

void main() {
  const uid = 'test-account';
  final root = List.filled(43, 'A').join();

  late AccountRecoveryVault vault;
  late AccountRecoveryKitCodec codec;
  late List<int> secret;
  late List<int> dataKey;
  late String kitCode;

  setUp(() async {
    vault = AccountRecoveryVault();
    codec = AccountRecoveryKitCodec();

    secret = await vault.generateLocalSecret();
    dataKey = await vault.generateLocalSecret();

    kitCode = await codec.encode(
      userUid: uid,
      rootFingerprint: root,
      recoverySecret: secret,
    );
  });

  test('Il kit conserva il segreto originale', () async {
    final recovered = await codec.decode(kitCode);

    expect(recovered.userUid, uid);
    expect(recovered.rootFingerprint, root);
    expect(recovered.recoverySecret, orderedEquals(secret));
  });

  test('Il kit funziona con una nuova istanza', () async {
    final anotherCodec = AccountRecoveryKitCodec();
    final recovered = await anotherCodec.decode(kitCode);

    expect(recovered.recoverySecret, orderedEquals(secret));
  });

  test('Il segreto recuperato apre il vault cifrato', () async {
    final envelope = await vault.seal(
      recoverySecret: secret,
      portableDataKey: dataKey,
      userUid: uid,
      rootFingerprint: root,
      revision: 1,
    );

    final imported = await AccountRecoveryKitCodec().decode(kitCode);

    final recoveredKey = await AccountRecoveryVault().open(
      envelope: envelope,
      recoverySecret: imported.recoverySecret,
      expectedUserUid: imported.userUid,
      expectedRootFingerprint: imported.rootFingerprint,
      expectedRevision: 1,
    );

    expect(recoveredKey, orderedEquals(dataKey));
  });

  test('Una modifica al codice viene rilevata', () async {
    final parts = kitCode.split('.');
    final original = parts[1];
    parts[1] = '${original[0] == 'A' ? 'B' : 'A'}${original.substring(1)}';

    await expectLater(codec.decode(parts.join('.')), throwsFormatException);
  });

  test('Un checksum errato viene rifiutato', () async {
    final parts = kitCode.split('.');
    parts[2] = 'INVALID';

    await expectLater(codec.decode(parts.join('.')), throwsFormatException);
  });

  test('Un formato sconosciuto viene rifiutato', () async {
    final changed = kitCode.replaceFirst('AMTR-REC-1', 'AMTR-REC-99');

    await expectLater(codec.decode(changed), throwsFormatException);
  });

  test('Spazi aggiunti vengono rifiutati', () async {
    await expectLater(codec.decode(' $kitCode '), throwsFormatException);
  });

  test('Segreti con lunghezza errata vengono rifiutati', () async {
    await expectLater(
      codec.encode(
        userUid: uid,
        rootFingerprint: root,
        recoverySecret: List<int>.filled(16, 1),
      ),
      throwsArgumentError,
    );
  });

  test('L impronta non valida viene rifiutata', () async {
    await expectLater(
      codec.encode(
        userUid: uid,
        rootFingerprint: 'fake-root',
        recoverySecret: secret,
      ),
      throwsArgumentError,
    );
  });

  test('Il kit decodificato non espone una lista modificabile', () async {
    final imported = await codec.decode(kitCode);

    expect(() => imported.recoverySecret[0] = 0, throwsUnsupportedError);
  });
}
