const test = require('node:test');
const assert = require('node:assert/strict');

const {initializeApp, deleteApp} =
  require('firebase-admin/app');

const {getFirestore} =
  require('firebase-admin/firestore');

const {
  AccountDeletionPreflight,
} = require(
  '../lib/account-deletion/account-deletion-preflight.js'
);

if (
  process.env.FIRESTORE_EMULATOR_HOST !==
  '127.0.0.1:18091'
) {
  throw new Error('Emulator isolation guard failed.');
}

const app = initializeApp(
  {projectId: 'demo-amaterasu-e2ee'},
  'amaterasu-macro-1'
);

const db = getFirestore(app);
const preflight = new AccountDeletionPreflight(db);

test.after(async () => {
  await db.terminate();
  await deleteApp(app);
});

async function trip(id, owner, members) {
  const ref = db.collection('trips').doc('macro1-' + id);

  await ref.set({
    ownerUid: owner,
    memberUids: members,
    name: id,
  });

  return ref;
}

function stateRef(uid) {
  return db.collection('_amaterasuAccountDeletionPreflight')
    .doc(uid);
}

test('account without trips remains pending full cleanup', async () => {
  const uid = 'macro1-empty-user';
  const result = await preflight.prepare(uid);

  assert.equal(
    result.stage,
    'pending_other_data_cleanup'
  );

  assert.equal(result.ownedTripCount, 0);
  assert.equal(result.participatingTripCount, 0);

  const saved = await stateRef(uid).get();

  assert.equal(saved.data().stage, result.stage);
  assert.ok(saved.data().checkedAt);
});

test('traveler is blocked pending E2EE revocation', async () => {
  const uid = 'macro1-traveler';
  const ref = await trip(
    'traveler-trip',
    'macro1-other-owner',
    ['macro1-other-owner', uid]
  );

  await ref.collection('members').doc(uid).set({
    uid,
    travellerProfile: {
      allergies: 'Sensitive test value',
    },
  });

  const result = await preflight.prepare(uid);

  assert.equal(
    result.stage,
    'blocked_e2ee_revocation'
  );

  assert.equal(result.participatingTripCount, 1);

  // Preflight must not delete membership or inspect health data.
  const member = await ref.collection('members')
    .doc(uid).get();

  assert.equal(member.exists, true);

  assert.equal(
    member.data().travellerProfile.allergies,
    'Sensitive test value'
  );

  const saved = (await stateRef(uid).get()).data();

  assert.equal(
    JSON.stringify(saved).includes('Sensitive test value'),
    false
  );
});

test('trip owner is blocked pending owner resolution', async () => {
  const uid = 'macro1-owner';
  await trip('owned-trip', uid, [uid]);

  const result = await preflight.prepare(uid);

  assert.equal(
    result.stage,
    'blocked_owner_resolution'
  );

  assert.equal(result.ownedTripCount, 1);
});

test('owner status takes priority over traveler cleanup', async () => {
  const uid = 'macro1-mixed';

  await trip('mixed-owned', uid, [uid]);

  await trip(
    'mixed-shared',
    'macro1-different-owner',
    ['macro1-different-owner', uid]
  );

  const result = await preflight.prepare(uid);

  assert.equal(result.stage, 'blocked_owner_resolution');
  assert.equal(result.ownedTripCount, 1);
  assert.equal(result.participatingTripCount, 1);
});

test('repeating preflight preserves a single status document', async () => {
  const uid = 'macro1-repeated-user';

  await preflight.prepare(uid);
  await preflight.prepare(uid);

  const saved = await stateRef(uid).get();

  assert.equal(saved.exists, true);
  assert.equal(saved.data().schemaVersion, 1);
  assert.equal(
    saved.data().stage,
    'pending_other_data_cleanup'
  );
});

test('invalid account identifiers are rejected', async () => {
  for (const uid of ['', ' ', 'bad/uid', '..']) {
    await assert.rejects(
      preflight.prepare(uid),
      /Invalid account UID/
    );
  }
});

test('preflight never removes trip membership', async () => {
  const uid = 'macro1-preserve-member';

  const ref = await trip(
    'preservation-trip',
    'macro1-preservation-owner',
    ['macro1-preservation-owner', uid]
  );

  await preflight.prepare(uid);

  const snapshot = await ref.get();

  assert.equal(
    snapshot.data().memberUids.includes(uid),
    true
  );
});