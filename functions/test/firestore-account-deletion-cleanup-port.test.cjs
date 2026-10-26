const test = require('node:test');
const assert = require('node:assert/strict');

const {
  FirestoreAccountDeletionCleanupPort,
} = require(process.argv[2]);

function fixture({
  ownerUid = 'owner',
  members = ['alice'],
  memberDocument = true,
  missingTrip = false,
  changeOwnerBeforeTransaction = false,
} = {}) {
  const record = missingTrip ? null : {
    ownerUid,
    memberUids: [...members],
    memberDocs: new Map(),
  };

  if (record && memberDocument) {
    record.memberDocs.set('alice', {uid: 'alice'});
  }

  const state = {
    record,
    writes: [],
  };

  const db = {
    collection(name) {
      assert.equal(name, 'trips');

      return {
        where(field, operation, uid) {
          return {
            async get() {
              const r = state.record;
              if (!r) return {docs: []};

              const found = field === 'ownerUid'
                ? operation === '==' && r.ownerUid === uid
                : field === 'memberUids' &&
                  operation === 'array-contains' &&
                  r.memberUids.includes(uid);

              return {docs: found ? [{id: 'trip-1'}] : []};
            },
          };
        },

        doc(tripId) {
          return {
            kind: 'trip',
            tripId,
            collection(collectionName) {
              assert.equal(collectionName, 'members');

              return {
                doc(uid) {
                  return {kind: 'member', tripId, uid};
                },
              };
            },
          };
        },
      };
    },

    async runTransaction(action) {
      if (changeOwnerBeforeTransaction && state.record) {
        state.record.ownerUid = 'alice';
      }

      const pending = [];

      const transaction = {
        async get(ref) {
          const r = state.record;

          if (ref.kind === 'trip') {
            return {
              exists: Boolean(r),
              data: () => r,
            };
          }

          const member = r?.memberDocs.get(ref.uid);

          return {
            exists: Boolean(member),
            data: () => member,
          };
        },

        update(ref, value) {
          pending.push({type: 'update', ref, value});
        },

        delete(ref) {
          pending.push({type: 'delete', ref});
        },
      };

      // Simulates atomic commit: failed callbacks apply no writes.
      await action(transaction);

      for (const operation of pending) {
        assert.ok(state.record);

        if (operation.type === 'delete') {
          state.record.memberDocs.delete(operation.ref.uid);
        } else {
          assert.ok(operation.value.memberUids);
          assert.ok(operation.value.updatedAt);

          state.record.memberUids =
            state.record.memberUids.filter(
              (uid) => uid !== 'alice',
            );
        }

        state.writes.push(operation.type);
      }
    },
  };

  return {
    state,
    port: new FirestoreAccountDeletionCleanupPort(db),
  };
}

test('valid participant removal updates both references', async () => {
  const f = fixture();

  await f.port.removeMembershipAtomically('trip-1', 'alice');

  assert.deepEqual(f.state.record.memberUids, []);
  assert.equal(f.state.record.memberDocs.has('alice'), false);
  assert.deepEqual(f.state.writes, ['update', 'delete']);
});

test('trip owner cannot be removed', async () => {
  const f = fixture({ownerUid: 'alice'});

  await assert.rejects(
    f.port.removeMembershipAtomically('trip-1', 'alice'),
    /trip owner/,
  );

  assert.deepEqual(f.state.writes, []);
});

test('missing trip fails without mutations', async () => {
  const f = fixture({missingTrip: true});

  await assert.rejects(
    f.port.removeMembershipAtomically('trip-1', 'alice'),
    /no longer exists/,
  );

  assert.deepEqual(f.state.writes, []);
});

test('missing membership document fails closed', async () => {
  const f = fixture({memberDocument: false});

  await assert.rejects(
    f.port.removeMembershipAtomically('trip-1', 'alice'),
    /Inconsistent trip membership/,
  );

  assert.deepEqual(f.state.writes, []);
});

test('missing membership array reference fails closed', async () => {
  const f = fixture({members: []});

  await assert.rejects(
    f.port.removeMembershipAtomically('trip-1', 'alice'),
    /Inconsistent trip membership/,
  );

  assert.deepEqual(f.state.writes, []);
});

test('owner change after preflight is caught in transaction', async () => {
  const f = fixture({changeOwnerBeforeTransaction: true});

  await assert.rejects(
    f.port.removeMembershipAtomically('trip-1', 'alice'),
    /trip owner/,
  );

  assert.deepEqual(f.state.writes, []);
});

test('inventory queries distinguish owner and participant', async () => {
  const participant = fixture();
  const owner = fixture({ownerUid: 'alice'});

  assert.deepEqual(
    await participant.port.listParticipatingTripIds('alice'),
    ['trip-1'],
  );

  assert.deepEqual(
    await participant.port.listOwnedTripIds('alice'),
    [],
  );

  assert.deepEqual(
    await owner.port.listOwnedTripIds('alice'),
    ['trip-1'],
  );
});

test('invalid document identifiers are rejected', async () => {
  const f = fixture();

  await assert.rejects(
    f.port.removeMembershipAtomically('bad/trip', 'alice'),
    /Invalid Trip ID/,
  );

  await assert.rejects(
    f.port.removeMembershipAtomically('trip-1', 'bad/uid'),
    /Invalid UID/,
  );

  assert.deepEqual(f.state.writes, []);
});