const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ts = require('typescript');
const crypto = require('node:crypto');

function loadTypeScript(filename, resolveModule = require) {
  const source = fs.readFileSync(
    path.resolve(__dirname, '../../src/security', filename),
    'utf8'
  );

  const compiled = ts.transpileModule(source, {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2020,
    },
  });

  const context = {
    exports: {},
    require: resolveModule,
    Buffer,
  };

  vm.runInNewContext(compiled.outputText, context, {
    filename,
  });

  return context.exports;
}

const verifier = loadTypeScript('device-approval-verifier.ts');

const {
  DeviceApprovalConsumptionGate: Gate,
} = loadTypeScript(
  'device-approval-consumption-gate.ts',
  name => {
    if (name === './device-approval-verifier') {
      return verifier;
    }
    return require(name);
  }
);

const NOW = 1800000000000;

const approver = crypto.generateKeyPairSync('ed25519');
const attacker = crypto.generateKeyPairSync('ed25519');
const newcomer = crypto.generateKeyPairSync('ed25519');
const encryption = crypto.generateKeyPairSync('x25519');

function publicBase64(key) {
  return key.export({
    format: 'der',
    type: 'spki',
  }).subarray(-32).toString('base64');
}

const trustedKey = publicBase64(approver.publicKey);

function fixture(challengeByte = 7) {
  const claim = {
    userUid: 'user-one',
    approverDeviceId: 'trusted-android',
    newDeviceId: 'new-chrome',
    newX25519PublicKey: publicBase64(encryption.publicKey),
    newEd25519PublicKey: publicBase64(newcomer.publicKey),
    challenge: Buffer.alloc(32, challengeByte).toString('base64'),
    issuedAtMs: NOW - 10000,
    expiresAtMs: NOW + 60000,
  };

  const signature = crypto.sign(
    null,
    verifier.deviceApprovalSigningBytes(claim),
    approver.privateKey,
  ).toString('base64');

  return {
    approval: {claim, signature},
    trustedApproverEd25519PublicKey: trustedKey,
    expected: {
      userUid: claim.userUid,
      approverDeviceId: claim.approverDeviceId,
      newDeviceId: claim.newDeviceId,
      newX25519PublicKey: claim.newX25519PublicKey,
      newEd25519PublicKey: claim.newEd25519PublicKey,
      challenge: claim.challenge,
    },
  };
}

function fakeLedger() {
  const consumed = new Set();
  let calls = 0;
  let failure = null;

  return {
    consumed,
    get calls() {
      return calls;
    },
    setFailure(error) {
      failure = error;
    },
    async consumeIfUnused(args) {
      calls++;

      if (failure) {
        throw failure;
      }

      const key = args.userUid + ':' + args.challenge;

      if (consumed.has(key)) {
        return false;
      }

      // Synchronous insertion simulates atomic create-if-absent.
      consumed.add(key);
      await Promise.resolve();
      return true;
    },
  };
}

function gate(ledger, clock = () => NOW) {
  return new Gate(ledger, clock);
}

test('accepts and consumes a valid signed approval', async () => {
  const ledger = fakeLedger();
  await gate(ledger).verifyAndConsume(fixture());

  assert.equal(ledger.calls, 1);
  assert.equal(ledger.consumed.size, 1);
});

test('invalid signature never reaches the ledger', async () => {
  const ledger = fakeLedger();
  const input = fixture();

  input.approval.signature =
    Buffer.alloc(64, 8).toString('base64');

  await assert.rejects(
    gate(ledger).verifyAndConsume(input),
    /Invalid signed device approval/
  );

  assert.equal(ledger.calls, 0);
});

test('substituted approver key never reaches the ledger', async () => {
  const ledger = fakeLedger();
  const input = fixture();

  input.trustedApproverEd25519PublicKey =
    publicBase64(attacker.publicKey);

  await assert.rejects(
    gate(ledger).verifyAndConsume(input),
    /Invalid signed device approval/
  );

  assert.equal(ledger.calls, 0);
});

test('wrong recipient never reaches the ledger', async () => {
  const ledger = fakeLedger();
  const input = fixture();

  input.expected.newDeviceId = 'other-device';

  await assert.rejects(
    gate(ledger).verifyAndConsume(input),
    /Invalid signed device approval/
  );

  assert.equal(ledger.calls, 0);
});

test('modified signed content never reaches the ledger', async () => {
  const ledger = fakeLedger();
  const input = fixture();

  input.approval.claim.newDeviceId = 'other-device';
  input.expected.newDeviceId = 'other-device';

  await assert.rejects(
    gate(ledger).verifyAndConsume(input),
    /Invalid signed device approval/
  );

  assert.equal(ledger.calls, 0);
});

test('expired approval never reaches the ledger', async () => {
  const ledger = fakeLedger();
  const input = fixture();

  await assert.rejects(
    gate(ledger, () => input.approval.claim.expiresAtMs)
      .verifyAndConsume(input),
    /Invalid signed device approval/
  );

  assert.equal(ledger.calls, 0);
});

test('second use is rejected', async () => {
  const ledger = fakeLedger();
  const service = gate(ledger);
  const input = fixture();

  await service.verifyAndConsume(input);

  await assert.rejects(
    service.verifyAndConsume(input),
    /already consumed/
  );

  assert.equal(ledger.consumed.size, 1);
});

test('replay is rejected across gate instances', async () => {
  const ledger = fakeLedger();
  const input = fixture();

  await gate(ledger).verifyAndConsume(input);

  await assert.rejects(
    gate(ledger).verifyAndConsume(input),
    /already consumed/
  );
});

test('concurrent approvals have exactly one winner', async () => {
  const ledger = fakeLedger();
  const service = gate(ledger);
  const input = fixture();

  const outcomes = await Promise.allSettled(
    Array.from(
      {length: 10},
      () => service.verifyAndConsume(input)
    )
  );

  assert.equal(
    outcomes.filter(result => result.status === 'fulfilled').length,
    1
  );

  assert.equal(ledger.consumed.size, 1);
});

test('ledger rejection prevents approval', async () => {
  const ledger = fakeLedger();

  await gate(ledger).verifyAndConsume(fixture());

  await assert.rejects(
    gate(ledger).verifyAndConsume(fixture()),
    /already consumed/
  );
});

test('ledger unavailability fails closed', async () => {
  const ledger = fakeLedger();
  ledger.setFailure(new Error('Database unavailable'));

  await assert.rejects(
    gate(ledger).verifyAndConsume(fixture()),
    /Database unavailable/
  );
});

test('invalid server clock fails before consuming', async () => {
  const ledger = fakeLedger();

  await assert.rejects(
    gate(ledger, () => NaN).verifyAndConsume(fixture()),
    /Invalid signed device approval/
  );

  assert.equal(ledger.calls, 0);
});

test('independent challenges may be consumed', async () => {
  const ledger = fakeLedger();
  const service = gate(ledger);

  await service.verifyAndConsume(fixture(7));
  await service.verifyAndConsume(fixture(8));

  assert.equal(ledger.consumed.size, 2);
});