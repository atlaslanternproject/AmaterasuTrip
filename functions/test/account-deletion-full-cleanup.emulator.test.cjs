const test = require('node:test');
const assert = require('node:assert/strict');

const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');

const {
  cleanupAccountTripMemberships,
  AccountDeletionOwnerResolutionRequired,
} = require('../lib/account-deletion/account-deletion-cleanup-orchestrator.js');

const {
  FirestoreAccountDeletionCleanupPort,
} = require('../lib/account-deletion/firestore-account-deletion-cleanup-port.js');

if (
  process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:18090'
) {
  throw new Error('Emulator isolation guard failed.');
}

const app = initializeApp(
  {projectId: 'demo-amaterasu-e2ee'},
  'amaterasu-6-7AN'
);

const db = getFirestore(app);
const port = new FirestoreAccountDeletionCleanupPort(db);

test.after(async () => {
  await db.terminate();
  await deleteApp(app);
});

async function createTrip(id, ownerUid, memberUid, valid = true) {
  const ref = db.collection('trips').doc('6-7AN-' + id);

  await ref.set({
    name: id,
    ownerUid,
    memberUids: ownerUid === memberUid
      ? [ownerUid]
      : [ownerUid, memberUid],
    status: 'active',
  });

  if (valid) {
    await ref.collection('members').doc(memberUid).set({
      uid: memberUid,
      role: ownerUid === memberUid ? 'admin' : 'traveler',
    });
  }

  return ref;
}

test('account without trips is ready for later cleanup stages', async () => {
  const result = await cleanupAccountTripMemberships(
    port,
    '6-7AN-empty-user'
  );

  assert.deepEqual(result.removedTripIds, []);
  assert.equal(result.remainingReferences, 0);
});

test('participant is removed from two real trips', async () => {
  const uid = '6-7AN-traveler';

  const first = await createTrip(
    'guest-a', 'owner-a', uid
  );

  const second = await createTrip(
    'guest-b', 'owner-b', uid
  );

  const result = await cleanupAccountTripMemberships(port, uid);

  assert.deepEqual(
    result.removedTripIds,
    [first.id, second.id]
  );

  for (const ref of [first, second]) {
    const snapshot = await ref.get();

    assert.equal(
      snapshot.data().memberUids.includes(uid),
      false
    );

    assert.equal(
      (await ref.collection('members').doc(uid).get()).exists,
      false
    );
  }
});

test('owner and traveler is blocked before any deletion', async () => {
  const uid = '6-7AN-owner';

  const owned = await createTrip(
    'owned', uid, uid
  );

  const shared = await createTrip(
    'shared', 'another-owner', uid
  );

  await assert.rejects(
    cleanupAccountTripMemberships(port, uid),
    AccountDeletionOwnerResolutionRequired
  );

  assert.ok((await owned.get()).data().memberUids.includes(uid));
  assert.ok((await shared.get()).data().memberUids.includes(uid));

  assert.equal(
    (await shared.collection('members').doc(uid).get()).exists,
    true
  );
});

test('partial failure is detected and never reported as success', async () => {
  const uid = '6-7AN-partial';

  const first = await createTrip(
    'partial-a', 'owner-a', uid
  );

  const broken = await createTrip(
    'partial-b', 'owner-b', uid, false
  );

  await assert.rejects(
    cleanupAccountTripMemberships(port, uid),
    /Inconsistent trip membership/
  );

  // First transaction committed, second failed.
  // The final production workflow must be resumable.
  assert.equal(
    (await first.get()).data().memberUids.includes(uid),
    false
  );

  assert.equal(
    (await broken.get()).data().memberUids.includes(uid),
    true
  );
});