import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/pinned_trip_epoch_store.dart';
import 'package:amaterasutrip/core/security/signed_trip_device_roster.dart';

class FakeStorage implements TrustedEpochRecordStorage {
  final Map<String, String> records = {};
  bool failRead = false;
  bool failWrite = false;

  @override
  Future<String?> read(String key) async {
    if (failRead) throw StateError('Storage read failed');
    return records[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrite) throw StateError('Storage write failed');
    records[key] = value;
  }
}

Future<(SignedTripDeviceRoster, SimplePublicKey)> makeRoster() async {
  final signing = await Ed25519().newKeyPair();
  final publicKey = await signing.extractPublicKey();

  final roster = await SignedTripDeviceRosterVerifier().sign(
    tripId: 'trip-japan',
    authorityUid: 'alice',
    authorityDeviceId: 'alice-android',
    epoch: 2,
    activeDevices: [
      RosterDevice(
        uid: 'alice',
        deviceId: 'alice-android',
        x25519Fingerprint: 'trusted-x25519-pin',
        ed25519PublicKeyBytes: publicKey.bytes,
      ),
    ],
    revokedMemberUids: {'former-member'},
    authorityEd25519KeyPair: signing,
  );

  return (roster, publicKey);
}

Future<void> bootstrap(
  PinnedTripEpochStore store,
  SignedTripDeviceRoster roster,
  SimplePublicKey pin,
) {
  return store.bootstrapFromVerifiedRoster(
    tripId: 'trip-japan',
    roster: roster,
    authorityUid: 'alice',
    authorityDeviceId: 'alice-android',
    independentlyPinnedAuthority: pin,
  );
}

void main() {
  test('unregistered device has no trusted epoch', () async {
    final store = PinnedTripEpochStore(uid: 'alice', storage: FakeStorage());
    expect(await store.readTrustedFloor('trip-japan'), isNull);
  });

  test('independently pinned signed roster bootstraps epoch', () async {
    final storage = FakeStorage();
    final store = PinnedTripEpochStore(uid: 'alice', storage: storage);
    final (roster, pin) = await makeRoster();

    await bootstrap(store, roster, pin);

    expect(await store.readTrustedFloor('trip-japan'), 2);
    expect(storage.records.length, 1);
  });

  test('trusted state survives new store instance', () async {
    final storage = FakeStorage();
    final (roster, pin) = await makeRoster();

    await bootstrap(
      PinnedTripEpochStore(uid: 'alice', storage: storage),
      roster,
      pin,
    );

    final reopened = PinnedTripEpochStore(uid: 'alice', storage: storage);

    expect(await reopened.readTrustedFloor('trip-japan'), 2);
  });

  test('old epoch cannot replace new epoch', () async {
    final store = PinnedTripEpochStore(uid: 'alice', storage: FakeStorage());
    final (roster, pin) = await makeRoster();

    await bootstrap(store, roster, pin);
    await store.advanceTrustedFloor('trip-japan', 4);

    await expectLater(
      store.advanceTrustedFloor('trip-japan', 3),
      throwsStateError,
    );

    expect(await store.readTrustedFloor('trip-japan'), 4);
  });

  test('a different account cannot read this trust record', () async {
    final storage = FakeStorage();
    final (roster, pin) = await makeRoster();

    await bootstrap(
      PinnedTripEpochStore(uid: 'alice', storage: storage),
      roster,
      pin,
    );

    final other = PinnedTripEpochStore(uid: 'bob', storage: storage);

    expect(await other.readTrustedFloor('trip-japan'), isNull);
  });

  test('invalid signing identity cannot bootstrap trust', () async {
    final store = PinnedTripEpochStore(uid: 'alice', storage: FakeStorage());
    final (roster, _) = await makeRoster();
    final attacker = await Ed25519().newKeyPair();

    await expectLater(
      bootstrap(store, roster, await attacker.extractPublicKey()),
      throwsStateError,
    );

    expect(await store.readTrustedFloor('trip-japan'), isNull);
  });

  test('missing bootstrap blocks advancement', () async {
    final store = PinnedTripEpochStore(uid: 'alice', storage: FakeStorage());

    await expectLater(
      store.advanceTrustedFloor('trip-japan', 2),
      throwsStateError,
    );
  });

  test('storage errors do not reset trusted epochs', () async {
    final storage = FakeStorage();
    final store = PinnedTripEpochStore(uid: 'alice', storage: storage);
    final (roster, pin) = await makeRoster();

    await bootstrap(store, roster, pin);
    storage.failWrite = true;

    await expectLater(
      store.advanceTrustedFloor('trip-japan', 3),
      throwsStateError,
    );

    storage.failWrite = false;
    expect(await store.readTrustedFloor('trip-japan'), 2);
  });

  test('corrupted stored state is rejected', () async {
    final storage = FakeStorage();
    final store = PinnedTripEpochStore(uid: 'alice', storage: storage);
    final (roster, pin) = await makeRoster();

    await bootstrap(store, roster, pin);

    final key = storage.records.keys.single;
    final record = jsonDecode(storage.records[key]!) as Map<String, dynamic>;
    record['epoch'] = -1;
    storage.records[key] = jsonEncode(record);

    await expectLater(
      store.readTrustedFloor('trip-japan'),
      throwsFormatException,
    );
  });

  test('duplicate bootstrap cannot replace a trusted authority', () async {
    final store = PinnedTripEpochStore(uid: 'alice', storage: FakeStorage());
    final (roster, pin) = await makeRoster();

    await bootstrap(store, roster, pin);

    await expectLater(bootstrap(store, roster, pin), throwsStateError);
  });

  test('concurrent updates within one store never regress', () async {
    final store = PinnedTripEpochStore(uid: 'alice', storage: FakeStorage());
    final (roster, pin) = await makeRoster();

    await bootstrap(store, roster, pin);

    final first = store.advanceTrustedFloor('trip-japan', 4);

    final secondRejected = expectLater(
      store.advanceTrustedFloor('trip-japan', 3),
      throwsStateError,
    );

    await first;
    await secondRejected;
    expect(await store.readTrustedFloor('trip-japan'), 4);
  });
}
