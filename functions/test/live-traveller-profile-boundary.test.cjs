const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const {
  requireEncryptedTravellerProfile,
  projectEncryptedTravellerProfile,
} = require('../lib/security/live-traveller-profile-boundary.js');

function envelope() {
  return {
    hasEsimOrInternet: true,
    hasCheckedBaggage: null,
    hasCabinBaggage10Kg: false,
    protectedDetails: {
      version: 1,
      algorithm: 'AES-256-GCM',
      nonce: Buffer.alloc(12, 1).toString('base64'),
      ciphertext: Buffer.alloc(32, 2).toString('base64'),
      mac: Buffer.alloc(16, 3).toString('base64'),
    },
  };
}

function isInvalidArgument(error) {
  return error && error.code === 'invalid-argument';
}

test('accepts an encrypted-only transport', () => {
  assert.deepEqual(requireEncryptedTravellerProfile(envelope()), envelope());
});

test('rejects legacy plaintext medical data', () => {
  assert.throws(() => requireEncryptedTravellerProfile({
    hasAllergies: true,
    allergies: 'Private health data',
  }), isInvalidArgument);
});

test('rejects encrypted transport with an extra plaintext field', () => {
  assert.throws(() => requireEncryptedTravellerProfile({
    ...envelope(),
    emergencyContactPhone: '+39 123456',
  }), isInvalidArgument);
});

test('rejects malformed envelope data', () => {
  const candidate = envelope();
  candidate.protectedDetails.nonce = 'invalid';
  assert.throws(() => requireEncryptedTravellerProfile(candidate), isInvalidArgument);
});

test('legacy stored plaintext is never projected', () => {
  assert.equal(projectEncryptedTravellerProfile({allergies: 'SECRET'}), null);
  assert.equal(projectEncryptedTravellerProfile(null), null);
});

test('valid encrypted payload is projected without decryption', () => {
  assert.deepEqual(projectEncryptedTravellerProfile(envelope()), envelope());
});

test('validation errors never include sensitive fields', () => {
  assert.throws(
    () => requireEncryptedTravellerProfile({allergies: 'HIGHLY_PRIVATE_TEST_VALUE'}),
    (error) => isInvalidArgument(error) &&
      !String(error).includes('HIGHLY_PRIVATE_TEST_VALUE'),
  );
});

// These are source regression guards, not a deployed Cloud Function test.
const index = fs.readFileSync(path.join(__dirname, '../src/index.ts'), 'utf8');
const inviteRepo = fs.readFileSync(
  path.join(__dirname, '../../lib/features/trips/data/repositories/trip_invite_repository.dart'),
  'utf8',
);
const memberRepo = fs.readFileSync(
  path.join(__dirname, '../../lib/features/trips/data/repositories/trip_member_repository.dart'),
  'utf8',
);
function section(start, end) {
  const a = index.indexOf(start);
  const b = index.indexOf(end, a + start.length);
  assert.ok(a >= 0 && b > a);
  return index.substring(a, b);
}

test('both writes accept encrypted transport only', () => {
  const parts = [
    section('export const acceptTripInvite =', 'export const listTripMembers ='),
    section('export const updateMyTripTravellerProfile =', 'export const removeTripMember ='),
  ];
  for (const part of parts) {
    assert.match(part, /requireEncryptedTravellerProfile\(/);
    assert.match(part, /travellerProfile: encryptedProfile/);
    assert.doesNotMatch(part, /allergies:\s/);
    assert.doesNotMatch(part, /emergencyContactPhone:\s/);
  }
});

test('profile update cannot resurrect a removed member', () => {
  const part = section('export const updateMyTripTravellerProfile =', 'export const removeTripMember =');
  assert.match(part, /db\.runTransaction/);
  assert.match(part, /transaction\.get\(memberRef\)/);
  assert.match(part, /!memberSnapshot\.exists/);
  assert.match(part, /transaction\.update\(memberRef/);
  assert.doesNotMatch(part, /FieldValue\.arrayUnion/);
  assert.doesNotMatch(part, /memberRef\.set/);
});

test('member listing redacts legacy and validates encrypted', () => {
  const part = section('export const listTripMembers =', 'export const updateMyTripTravellerProfile =');
  assert.match(part, /projectEncryptedTravellerProfile/);
  assert.match(part, /legacy-redacted/);
  assert.match(part, /activeUids\.has\(memberSnapshot\.id\)/);
  assert.doesNotMatch(part, /memberData\.travellerProfile\s*\?\?/);
});

test('legacy Flutter entrypoints cannot transmit plaintext', () => {
  const accept = inviteRepo.split('Future<void> acceptTripInvite({')[1]
    .split('Future<void> acceptTripInviteEncrypted({')[0];
  const update = memberRepo.split('Future<void> updateMyTravellerProfile({')[1]
    .split('Future<void> updateMyTravellerProfileEncrypted({')[0];
  for (const part of [accept, update]) {
    assert.match(part, /throw StateError\(/);
    assert.doesNotMatch(part, /httpsCallable\(/);
  }
});
