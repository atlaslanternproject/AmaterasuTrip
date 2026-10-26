const test = require('node:test');
const assert = require('node:assert/strict');

const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');

const {FirestoreAccountDeletionCleanupPort} = require(
  '../lib/account-deletion/firestore-account-deletion-cleanup-port.js'
);

// Mandatory isolation guard: NEVER run against production.
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;

if (!/^(127\.0\.0\.1|localhost):18089$/.test(emulatorHost || '')) {
  throw new Error('Firestore Emulator isolation guard failed.');
}

const app = initializeApp(
  {projectId: 'demo-amaterasu-e2ee'},
  'amaterasu-6-7AM'
);

const db = getFirestore(app);
const port = new FirestoreAccountDeletionCleanupPort(db);

test.after(async () => {
  await db.terminate();
  await deleteApp(app);
});

async function seed(name, {
  ownerUid = 'owner-test',
  memberUids = ['alice-test'],
  memberDocument = true,
  memberDocumentUid = 'alice-test',
} = {}) {
  const ref = db.collection('trips').doc(`6-7AM-${name}`);

  await ref.set({
    name: name,
    ownerUid,
    memberUids,
    status: 'active',
  });

  if (memberDocument) {
    await ref.collection('members').doc('alice-test').set({
      uid: memberDocumentUid,
      role: 'traveler',
    });
  }

  return ref;
}

test('real transaction removes participant from both documents', async () => {
  const ref = await seed('valid');

  await port.removeMembershipAtomically(ref.id, 'alice-test');

  const trip = await ref.get();
  const member = await ref.collection('members')
    .doc('alice-test').get();

  assert.deepEqual(trip.data().memberUids, []);
  assert.equal(member.exists, false);
  assert.ok(trip.data().updatedAt);
});

test('owner cannot be removed in a real transaction', async () => {
  const ref = await seed('owner', {ownerUid: 'alice-test'});

  await assert.rejects(
    port.removeMembershipAtomically(ref.id, 'alice-test'),
    /trip owner/
  );

  assert.equal((await ref.collection('members')
    .doc('alice-test').get()).exists, true);

  assert.deepEqual((await ref.get()).data().memberUids, [
    'alice-test',
  ]);
});

test('missing trip fails without creating documents', async () => {
  const ref = db.collection('trips').doc('6-7AM-missing');

  await assert.rejects(
    port.removeMembershipAtomically(ref.id, 'alice-test'),
    /no longer exists/
  );

  assert.equal((await ref.get()).exists, false);
});

test('missing member document cannot produce partial removal', async () => {
  const ref = await seed('missing-member', {
    memberDocument: false,
  });

  await assert.rejects(
    port.removeMembershipAtomically(ref.id, 'alice-test'),
    /Inconsistent trip membership/
  );

  assert.deepEqual((await ref.get()).data().memberUids, [
    'alice-test',
  ]);
});

test('inconsistent UID cannot produce partial removal', async () => {
  const ref = await seed('wrong-member-uid', {
    memberDocumentUid: 'another-user',
  });

  await assert.rejects(
    port.removeMembershipAtomically(ref.id, 'alice-test'),
    /Inconsistent trip membership/
  );

  assert.deepEqual((await ref.get()).data().memberUids, [
    'alice-test',
  ]);
});

test('missing array membership cannot delete member document', async () => {
  const ref = await seed('missing-array', {
    memberUids: [],
  });

  await assert.rejects(
    port.removeMembershipAtomically(ref.id, 'alice-test'),
    /Inconsistent trip membership/
  );

  assert.equal((await ref.collection('members')
    .doc('alice-test').get()).exists, true);
});

test('inventory reads actual owner and participant indexes', async () => {
  const uid = 'inventory-user-6-7AM';

  const owned = await seed('inventory-owned', {
    ownerUid: uid,
    memberUids: [uid],
    memberDocument: false,
  });

  const participant = await seed('inventory-participant', {
    ownerUid: 'another-owner',
    memberUids: [uid],
    memberDocument: false,
  });

  const ownedIds = await port.listOwnedTripIds(uid);
  const memberIds = await port.listParticipatingTripIds(uid);

  assert.ok(ownedIds.includes(owned.id));
  assert.ok(memberIds.includes(owned.id));
  assert.ok(memberIds.includes(participant.id));
  assert.equal(ownedIds.includes(participant.id), false);
});

test('concurrent removals cannot both succeed', async () => {
  const ref = await seed('concurrent');

  const outcomes = await Promise.allSettled([
    port.removeMembershipAtomically(ref.id, 'alice-test'),
    port.removeMembershipAtomically(ref.id, 'alice-test'),
  ]);

  assert.equal(
    outcomes.filter(result => result.status === 'fulfilled').length,
    1
  );

  assert.equal(
    outcomes.filter(result => result.status === 'rejected').length,
    1
  );

  assert.deepEqual((await ref.get()).data().memberUids, []);

  assert.equal((await ref.collection('members')
    .doc('alice-test').get()).exists, false);
});