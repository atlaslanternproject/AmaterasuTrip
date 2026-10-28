const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../../');
function read(rel) { return fs.readFileSync(path.join(root, rel), 'utf8'); }
test('invitation UI invokes only encrypted callable', () => {
  const src = read('lib/features/trips/presentation/pages/invite/trip_traveller_questionnaire_page.dart');
  assert.match(src, /\.acceptTripInviteEncrypted\(/);
  assert.doesNotMatch(src, /\.acceptTripInvite\(/);
  assert.doesNotMatch(src, /debugPrintStack/);
});
test('personal questionnaire editor uses encrypted owner flow', () => {
  const src = read(
    'lib/features/trips/presentation/pages/workspace/settings/travellers/trip_traveller_profile_edit_page.dart'
  );

  const repo = read(
    'lib/features/trips/data/repositories/trip_member_repository.dart'
  );

  const vault = read(
    'lib/core/security/personal_profile_key_vault.dart'
  );

  const backend = read('functions/src/index.ts');

  // Editor never submits the legacy plaintext update.
  assert.match(src, /\.saveMyPersonalProfile\(/);
  assert.doesNotMatch(src, /\.updateMyTravellerProfile\(/);

  // Profile must be encrypted on the client.
  assert.match(repo, /TravellerHealthTransportCodec\(\)\.seal\(/);
  assert.match(repo, /httpsCallable\('updateMyTripTravellerProfile'\)/);

  // Only the authenticated owner may save their own answers.
  assert.match(repo, /uid != member\.uid/);

  // Encryption key is stored separately from Firebase Auth.
  assert.match(vault, /FlutterSecureStorage/);
  assert.match(vault, /AesGcm\.with256bits\(\)/);

  // A candidate key is staged, not immediately made active.
  assert.match(vault, /'pending'/);
  assert.match(vault, /'active'/);

  // Promotion must happen after the backend confirms the write.
  const confirmed = repo.indexOf("response.data['updated'] != true");
  const promoted = repo.indexOf(
    'await vault.promote(uid, tripId, key);'
  );

  assert.ok(confirmed >= 0);
  assert.ok(promoted > confirmed);

  // Server requires ciphertext and checks record revision.
  assert.match(backend, /requireEncryptedTravellerProfile\(profile\)/);
  assert.match(backend, /expectedProfileRevision/);
  assert.match(backend, /profileRecoveryHistory/);
  assert.match(backend, /transaction\.update\(memberRef/);
});
test('encryption requires a session lease, not raw caller-controlled keys', () => {
  for (const rel of [
    'lib/features/trips/data/repositories/trip_invite_repository.dart',
    'lib/features/trips/data/repositories/trip_member_repository.dart',
  ]) {
    const src = read(rel);
    assert.match(src, /verifiedSession\.requireKey\(/);
    assert.doesNotMatch(src, /verifiedProfileKey/);
  }
});
test('read path decrypts through authenticated bridge', () => {
  const src = read('lib/features/trips/data/repositories/trip_member_repository.dart');
  assert.match(src, /TripTravellerE2eeBridge\(\)\.openMember\(/);
  assert.match(src, /legacy-redacted/);
  assert.doesNotMatch(src, /\.whereType<Map>\(\)/);
});
test('session creation verifies signed rotation and trusted monotonic epoch', () => {
  const src = read('lib/core/security/verified_trip_profile_sessions.dart');
  assert.match(src, /VerifiedTripRotationReader\(trustedEpochStore\)\.open\(/);
  assert.match(src, /AuthenticatedProfileKeyExchange\(\)\.receive\(/);
  assert.match(src, /readTrustedFloor\(tripId\)/);
  assert.doesNotMatch(src, /FirebaseFirestore/);
});
