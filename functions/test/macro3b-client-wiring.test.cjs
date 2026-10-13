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
test('edit UI invokes only encrypted callable', () => {
  const src = read('lib/features/trips/presentation/pages/workspace/settings/travellers/trip_traveller_profile_edit_page.dart');
  assert.match(src, /\.updateMyTravellerProfileEncrypted\(/);
  assert.doesNotMatch(src, /\.updateMyTravellerProfile\(/);
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
