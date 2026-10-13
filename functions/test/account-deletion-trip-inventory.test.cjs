const test = require('node:test');
const assert = require('node:assert/strict');

const compiled = require(process.argv[2]);
const plan = compiled.planAccountDeletionTrips;

test('account without trips has no references', () => {
  assert.deepEqual(plan([], []), {
    ownedTripIds: [],
    participatingTripIds: [],
    requiresOwnerResolution: false,
    requiresMembershipCleanup: false,
  });
});

test('participant trips require membership cleanup', () => {
  const result = plan([], ['trip-b', 'trip-a']);
  assert.deepEqual(result.participatingTripIds, ['trip-a', 'trip-b']);
  assert.equal(result.requiresMembershipCleanup, true);
  assert.equal(result.requiresOwnerResolution, false);
});

test('owned trips require explicit owner resolution', () => {
  const result = plan(['trip-owner'], ['trip-owner', 'trip-guest']);
  assert.deepEqual(result.ownedTripIds, ['trip-owner']);
  assert.deepEqual(result.participatingTripIds, ['trip-guest']);
  assert.equal(result.requiresOwnerResolution, true);
});

test('duplicates are removed and invalid references rejected', () => {
  assert.deepEqual(
    plan(['trip-a', 'trip-a'], ['trip-a', 'trip-b', 'trip-b'])
      .participatingTripIds,
    ['trip-b'],
  );

  assert.throws(() => plan([''], []));
  assert.throws(() => plan([], [' ']));
});