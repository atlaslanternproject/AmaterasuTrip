const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ts = require('typescript');

const source = fs.readFileSync(
  path.resolve(
    __dirname,
    '../../src/security/device-approval-replay-firestore.ts'
  ),
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

const Ledger = context.exports.FirestoreDeviceApprovalReplayLedger;

const NOW = 1800000000000;

function fixture() {
  return {
    userUid: 'user-one',
    challenge: Buffer.alloc(32, 7).toString('base64'),
    expiresAtMs: NOW + 60000,
  };
}

function fakeFirestore() {
  const documents = new Map();
  let injectedError = null;

  const db = {
    collection(name) {
      assert.equal(name, 'deviceApprovalReplayV1');

      return {
        doc(id) {
          assert.match(id, /^[0-9a-f]{64}$/);

          return {
            async create(data) {
              if (injectedError) throw injectedError;

              if (documents.has(id)) {
                const error = new Error('Already exists');
                error.code = 6;
                throw error;
              }

              // Simulates Firestore's atomic create-if-absent.
              documents.set(id, {...data});

              await Promise.resolve();
            },
          };
        },
      };
    },
  };

  return {
    db,
    documents,
    inject(error) {
      injectedError = error;
    },
  };
}

function ledger(store, now = NOW) {
  return new Ledger(store.db, () => now);
}

test('first use succeeds', async () => {
  const store = fakeFirestore();

  assert.equal(
    await ledger(store).consumeIfUnused(fixture()),
    true
  );

  assert.equal(store.documents.size, 1);
});

test('second use of the same challenge is rejected', async () => {
  const store = fakeFirestore();
  const service = ledger(store);

  assert.equal(await service.consumeIfUnused(fixture()), true);
  assert.equal(await service.consumeIfUnused(fixture()), false);
});

test('replay remains blocked after creating a new service instance', async () => {
  const store = fakeFirestore();

  assert.equal(await ledger(store).consumeIfUnused(fixture()), true);
  assert.equal(await ledger(store).consumeIfUnused(fixture()), false);
});

test('concurrent uses have exactly one winner', async () => {
  const store = fakeFirestore();
  const service = ledger(store);

  const results = await Promise.all(
    Array.from(
      {length: 12},
      () => service.consumeIfUnused(fixture())
    )
  );

  assert.equal(results.filter(Boolean).length, 1);
  assert.equal(store.documents.size, 1);
});

test('the same challenge belongs to separate accounts', async () => {
  const store = fakeFirestore();
  const service = ledger(store);

  const first = fixture();
  const second = {...fixture(), userUid: 'user-two'};

  assert.equal(await service.consumeIfUnused(first), true);
  assert.equal(await service.consumeIfUnused(second), true);
  assert.equal(store.documents.size, 2);
});

test('different challenges may be consumed independently', async () => {
  const store = fakeFirestore();
  const service = ledger(store);

  const first = fixture();
  const second = {
    ...fixture(),
    challenge: Buffer.alloc(32, 8).toString('base64'),
  };

  assert.equal(await service.consumeIfUnused(first), true);
  assert.equal(await service.consumeIfUnused(second), true);
});

test('the record contains no UID, challenge or private key', async () => {
  const store = fakeFirestore();

  await ledger(store).consumeIfUnused(fixture());

  const record = [...store.documents.values()][0];

  assert.deepEqual(Object.keys(record).sort(), [
    'consumedAtMs',
    'expiresAtMs',
    'version',
  ]);

  assert.equal(
    JSON.stringify(record).includes(fixture().challenge),
    false
  );
  assert.equal(
    JSON.stringify(record).includes(fixture().userUid),
    false
  );
});

test('rejects an expired challenge without writing', async () => {
  const store = fakeFirestore();

  await assert.rejects(
    ledger(store).consumeIfUnused({
      ...fixture(),
      expiresAtMs: NOW,
    })
  );

  assert.equal(store.documents.size, 0);
});

test('rejects an excessively distant expiry', async () => {
  const store = fakeFirestore();

  await assert.rejects(
    ledger(store).consumeIfUnused({
      ...fixture(),
      expiresAtMs: NOW + 330001,
    })
  );
});

test('rejects a short challenge', async () => {
  const store = fakeFirestore();

  await assert.rejects(
    ledger(store).consumeIfUnused({
      ...fixture(),
      challenge: Buffer.alloc(16, 3).toString('base64'),
    })
  );
});

test('rejects an all-zero challenge', async () => {
  const store = fakeFirestore();

  await assert.rejects(
    ledger(store).consumeIfUnused({
      ...fixture(),
      challenge: Buffer.alloc(32).toString('base64'),
    })
  );
});

test('rejects invalid Base64', async () => {
  const store = fakeFirestore();

  await assert.rejects(
    ledger(store).consumeIfUnused({
      ...fixture(),
      challenge: 'NOT_BASE64',
    })
  );
});

test('rejects an invalid account identifier', async () => {
  const store = fakeFirestore();

  await assert.rejects(
    ledger(store).consumeIfUnused({
      ...fixture(),
      userUid: '../other-account',
    })
  );
});

test('backend failure propagates without granting success', async () => {
  const store = fakeFirestore();
  const error = new Error('Database unavailable');
  error.code = 14;

  store.inject(error);

  await assert.rejects(
    ledger(store).consumeIfUnused(fixture()),
    /Database unavailable/
  );

  assert.equal(store.documents.size, 0);
});

test('unexpected Firestore errors are not treated as replay', async () => {
  const store = fakeFirestore();
  const error = new Error('Permission denied');
  error.code = 7;

  store.inject(error);

  await assert.rejects(
    ledger(store).consumeIfUnused(fixture()),
    /Permission denied/
  );
});

test('invalid server clock fails closed', async () => {
  const store = fakeFirestore();

  await assert.rejects(
    ledger(store, NaN).consumeIfUnused(fixture())
  );

  assert.equal(store.documents.size, 0);
});