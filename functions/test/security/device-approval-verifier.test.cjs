const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ts = require('typescript');
const {
  generateKeyPairSync,
  sign,
} = require('node:crypto');

const source = fs.readFileSync(
  path.resolve(__dirname, '../../src/security/device-approval-verifier.ts'),
  'utf8'
);

const compiled = ts.transpileModule(source, {
  compilerOptions: {
    module: ts.ModuleKind.CommonJS,
    target: ts.ScriptTarget.ES2020,
  },
});

const context = {exports: {}, require, Buffer};
vm.runInNewContext(compiled.outputText, context);

const {
  verifyDeviceApproval,
  deviceApprovalSigningBytes,
} = context.exports;

const now = 1800000000000;
const approver = generateKeyPairSync('ed25519');
const attacker = generateKeyPairSync('ed25519');

function publicBytes(key) {
  return key.export({format: 'der', type: 'spki'}).subarray(-32);
}

function publicBase64(key) {
  return publicBytes(key).toString('base64');
}

function fixtureClaim() {
  return {
    userUid: 'user-1',
    approverDeviceId: 'trusted-device',
    newDeviceId: 'new-device',
    newX25519PublicKey: Buffer.alloc(32, 3).toString('base64'),
    newEd25519PublicKey: Buffer.alloc(32, 4).toString('base64'),
    challenge: Buffer.alloc(32, 5).toString('base64'),
    issuedAtMs: now - 10000,
    expiresAtMs: now + 60000,
  };
}

function signed(claim, privateKey = approver.privateKey) {
  return {
    claim,
    signature: sign(
      null,
      deviceApprovalSigningBytes(claim),
      privateKey,
    ).toString('base64'),
  };
}

function expected(claim) {
  return {
    userUid: claim.userUid,
    approverDeviceId: claim.approverDeviceId,
    newDeviceId: claim.newDeviceId,
    newX25519PublicKey: claim.newX25519PublicKey,
    newEd25519PublicKey: claim.newEd25519PublicKey,
    challenge: claim.challenge,
  };
}

function checkFailure(name, operation) {
  test(name, () => {
    assert.throws(
      operation,
      /Invalid signed device approval/
    );
  });
}

test('accepts a valid Ed25519 signature with trusted key', () => {
  const claim = fixtureClaim();
  const approval = signed(claim);

  const verified = verifyDeviceApproval(
    approval,
    publicBase64(approver.publicKey),
    expected(claim),
    now,
  );

  assert.equal(verified.newDeviceId, 'new-device');
});

test('reconstructs canonical Dart signing array', () => {
  const claim = fixtureClaim();
  const actual = deviceApprovalSigningBytes(claim).toString('utf8');

  const expectedJson = JSON.stringify([
    'amaterasutrip',
    'device-approval',
    1,
    'user-1',
    'trusted-device',
    'new-device',
    claim.newX25519PublicKey,
    claim.newEd25519PublicKey,
    claim.challenge,
    claim.issuedAtMs,
    claim.expiresAtMs,
  ]);

  assert.equal(actual, expectedJson);
});

checkFailure('rejects an attacker signature', () => {
  const claim = fixtureClaim();
  verifyDeviceApproval(
    signed(claim, attacker.privateKey),
    publicBase64(approver.publicKey),
    expected(claim),
    now,
  );
});

checkFailure('rejects a substituted trusted key', () => {
  const claim = fixtureClaim();
  verifyDeviceApproval(
    signed(claim),
    publicBase64(attacker.publicKey),
    expected(claim),
    now,
  );
});

for (const [name, field, replacement] of [
  ['wrong user', 'userUid', 'other-user'],
  ['wrong approver', 'approverDeviceId', 'other-device'],
  ['wrong recipient', 'newDeviceId', 'other-recipient'],
  ['wrong X25519 key', 'newX25519PublicKey',
    Buffer.alloc(32, 6).toString('base64')],
  ['wrong Ed25519 key', 'newEd25519PublicKey',
    Buffer.alloc(32, 7).toString('base64')],
  ['wrong challenge', 'challenge',
    Buffer.alloc(32, 8).toString('base64')],
]) {
  checkFailure('rejects ' + name, () => {
    const claim = fixtureClaim();
    const trustedExpectations = expected(claim);
    trustedExpectations[field] = replacement;

    verifyDeviceApproval(
      signed(claim),
      publicBase64(approver.publicKey),
      trustedExpectations,
      now,
    );
  });
}

checkFailure('rejects expired approval', () => {
  const claim = fixtureClaim();
  verifyDeviceApproval(
    signed(claim),
    publicBase64(approver.publicKey),
    expected(claim),
    claim.expiresAtMs,
  );
});

checkFailure('rejects excessive future timestamp', () => {
  const claim = fixtureClaim();
  claim.issuedAtMs = now + 30001;
  claim.expiresAtMs = now + 90000;

  verifyDeviceApproval(
    signed(claim),
    publicBase64(approver.publicKey),
    expected(claim),
    now,
  );
});

checkFailure('rejects excessive approval lifetime', () => {
  const claim = fixtureClaim();
  claim.expiresAtMs = claim.issuedAtMs + 300001;

  verifyDeviceApproval(
    signed(claim),
    publicBase64(approver.publicKey),
    expected(claim),
    now,
  );
});

checkFailure('rejects changed signed content', () => {
  const claim = fixtureClaim();
  const approval = signed(claim);
  approval.claim.newDeviceId = 'altered-device';

  verifyDeviceApproval(
    approval,
    publicBase64(approver.publicKey),
    expected(approval.claim),
    now,
  );
});

checkFailure('rejects extra private key field', () => {
  const claim = fixtureClaim();
  const approval = signed(claim);
  approval.privateKey = 'NEVER_ACCEPT';

  verifyDeviceApproval(
    approval,
    publicBase64(approver.publicKey),
    expected(claim),
    now,
  );
});

checkFailure('rejects empty challenge', () => {
  const claim = fixtureClaim();
  claim.challenge = Buffer.alloc(32).toString('base64');

  verifyDeviceApproval(
    signed(claim),
    publicBase64(approver.publicKey),
    expected(claim),
    now,
  );
});

checkFailure('rejects malformed signature', () => {
  const claim = fixtureClaim();
  const approval = signed(claim);
  approval.signature = 'INVALID';

  verifyDeviceApproval(
    approval,
    publicBase64(approver.publicKey),
    expected(claim),
    now,
  );
});

checkFailure('rejects invalid timestamp', () => {
  const claim = fixtureClaim();
  claim.issuedAtMs = 1.5;

  verifyDeviceApproval(
    signed(claim),
    publicBase64(approver.publicKey),
    expected(claim),
    now,
  );
});