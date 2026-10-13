const test = require('node:test');
const assert = require('node:assert/strict');

const {
  cleanupAccountTripMemberships,
  AccountDeletionOwnerResolutionRequired,
} = require(process.argv[2]);

function fakeStore({
  owned = [],
  participating = [],
  failRemoval = false,
  keepMembership = false,
} = {}) {
  const state = {
    owned: [...owned],
    participating: [...participating],
    removed: [],
  };

  return {
    state,

    async listOwnedTripIds() {
      return [...state.owned];
    },

    async listParticipatingTripIds() {
      return [...state.participating];
    },

    async removeMembershipAtomically(tripId) {
      if (failRemoval) {
        throw new Error('Simulated transaction failure');
      }

      state.removed.push(tripId);

      if (!keepMembership) {
        state.participating =
          state.participating.filter((id) => id !== tripId);
      }
    },
  };
}

test('account without trips needs no cleanup', async () => {
  const store = fakeStore();

  const result = await cleanupAccountTripMemberships(
    store, 'alice',
  );

  assert.deepEqual(result.removedTripIds, []);
  assert.equal(result.remainingReferences, 0);
  assert.deepEqual(store.state.removed, []);
});

test('participant-only account is cleaned through adapter', async () => {
  const store = fakeStore({
    participating: ['trip-b', 'trip-a', 'trip-b'],
  });

  const result = await cleanupAccountTripMemberships(
    store, 'alice',
  );

  assert.deepEqual(result.removedTripIds, ['trip-a', 'trip-b']);
  assert.deepEqual(store.state.participating, []);
});

test('owner is blocked without any membership removal', async () => {
  const store = fakeStore({
    owned: ['trip-owned'],
  });

  await assert.rejects(
    cleanupAccountTripMemberships(store, 'alice'),
    AccountDeletionOwnerResolutionRequired,
  );

  assert.deepEqual(store.state.removed, []);
});

test('mixed owner and traveler is blocked before mutations', async () => {
  const store = fakeStore({
    owned: ['trip-owned'],
    participating: ['trip-owned', 'trip-shared'],
  });

  await assert.rejects(
    cleanupAccountTripMemberships(store, 'alice'),
    AccountDeletionOwnerResolutionRequired,
  );

  assert.deepEqual(store.state.removed, []);
});

test('transaction failure stops cleanup', async () => {
  const store = fakeStore({
    participating: ['trip-a'],
    failRemoval: true,
  });

  await assert.rejects(
    cleanupAccountTripMemberships(store, 'alice'),
    /Simulated transaction failure/,
  );

  assert.deepEqual(store.state.participating, ['trip-a']);
});

test('remaining membership references cause failure', async () => {
  const store = fakeStore({
    participating: ['trip-a'],
    keepMembership: true,
  });

  await assert.rejects(
    cleanupAccountTripMemberships(store, 'alice'),
    /Trip references remain/,
  );
});

test('invalid user identity is rejected', async () => {
  const store = fakeStore();

  await assert.rejects(
    cleanupAccountTripMemberships(store, ' '),
    /Invalid authenticated account UID/,
  );

  assert.deepEqual(store.state.removed, []);
});