const test = require("node:test");
const assert = require("node:assert/strict");

const {
  registerFirstRootTransaction,
} = require("../../lib/security/first-root-registration-transaction");

// Deterministic in-memory transaction simulator.
//
// The simulator serialises commits and applies all writes atomically.
// It is NOT the official Firestore emulator and cannot prove
// real Firestore retry or contention behaviour.
function createDb(initial = {}) {
  const documents = new Map(
    Object.entries(initial).map(([key, value]) => [
      key, structuredClone(value),
    ]),
  );

  let queue = Promise.resolve();
  let failNextCommit = false;

  return {
    collection(collectionName) {
      return {
        doc(uid) {
          return {path: `${collectionName}/${uid}`};
        },
      };
    },

    runTransaction(callback) {
      const execute = async () => {
        const writes = [];
        let writingStarted = false;

        const transaction = {
          async get(reference) {
            if (writingStarted) {
              throw new Error("Read after transaction write.");
            }

            return {
              exists: documents.has(reference.path),
            };
          },

          create(reference, value) {
            writingStarted = true;

            if (writes.some((entry) =>
              entry.path === reference.path)) {
              throw new Error("Duplicate write in transaction.");
            }

            writes.push({
              path: reference.path,
              value: structuredClone(value),
            });
          },
        };

        await callback(transaction);

        if (failNextCommit) {
          failNextCommit = false;
          throw new Error("Simulated atomic commit failure.");
        }

        // Abort the entire transaction when a write conflicts.
        if (writes.some((entry) => documents.has(entry.path))) {
          throw new Error("Create precondition failed.");
        }

        // No write is visible until validation has completed.
        for (const entry of writes) {
          documents.set(entry.path, entry.value);
        }
      };

      // One serialised execution models a committed transaction.
      const result = queue.then(execute, execute);
      queue = result.then(
        () => undefined,
        () => undefined,
      );
      return result;
    },

    snapshot() {
      return Object.fromEntries(
        [...documents.entries()].map(([key, value]) => [
          key, structuredClone(value),
        ]),
      );
    },

    failOnce() {
      failNextCommit = true;
    },
  };
}

const nowMs = 1800000000000;

function root(uid, deviceId) {
  return {
    version: 1,
    userUid: uid,
    deviceId,
    fingerprint: `fingerprint-${deviceId}`,
    publicTestMarker: true,
  };
}

function rootPath(uid) {
  return `e2eeRoots/${uid}`;
}

function ledgerPath(uid) {
  return `e2eeRootCreationLedgerV1/${uid}`;
}

test("First registration atomically creates both records", async () => {
  const db = createDb();
  const candidate = root("user-a", "device-a");

  await registerFirstRootTransaction(
    db, "user-a", candidate, nowMs,
  );

  const saved = db.snapshot();

  assert.equal(Object.keys(saved).length, 2);
  assert.deepEqual(saved[rootPath("user-a")], candidate);
  assert.equal(
    saved[ledgerPath("user-a")].deviceId,
    "device-a",
  );
  assert.equal(
    saved[ledgerPath("user-a")].registeredAtMs,
    nowMs,
  );
});

test("Repeated registration cannot replace the root", async () => {
  const db = createDb();

  await registerFirstRootTransaction(
    db, "user-a", root("user-a", "device-a"), nowMs,
  );

  const before = db.snapshot();

  await assert.rejects(
    registerFirstRootTransaction(
      db, "user-a", root("user-a", "device-a"), nowMs,
    ),
    (error) => error.code === "already-exists",
  );

  assert.deepEqual(db.snapshot(), before);
});

test("Another first device cannot replace the root", async () => {
  const db = createDb();

  await registerFirstRootTransaction(
    db, "user-a", root("user-a", "device-a"), nowMs,
  );

  const before = db.snapshot();

  await assert.rejects(
    registerFirstRootTransaction(
      db, "user-a", root("user-a", "device-b"), nowMs,
    ),
    (error) => error.code === "already-exists",
  );

  assert.deepEqual(db.snapshot(), before);
});

test("Existing root without ledger blocks registration", async () => {
  const first = root("user-a", "device-old");

  const db = createDb({
    [rootPath("user-a")]: first,
  });

  await assert.rejects(
    registerFirstRootTransaction(
      db, "user-a", root("user-a", "device-new"), nowMs,
    ),
    (error) => error.code === "already-exists",
  );

  assert.deepEqual(
    db.snapshot(),
    {[rootPath("user-a")]: first},
  );
});

test("Existing ledger without root blocks registration", async () => {
  const historical = {
    version: 1,
    userUid: "user-a",
    deviceId: "device-original",
  };

  const db = createDb({
    [ledgerPath("user-a")]: historical,
  });

  await assert.rejects(
    registerFirstRootTransaction(
      db, "user-a", root("user-a", "device-new"), nowMs,
    ),
    (error) => error.code === "already-exists",
  );

  assert.deepEqual(
    db.snapshot(),
    {[ledgerPath("user-a")]: historical},
  );
});

test("Two concurrent requests have only one winner", async () => {
  const db = createDb();

  const results = await Promise.allSettled([
    registerFirstRootTransaction(
      db, "user-a", root("user-a", "device-one"), nowMs,
    ),
    registerFirstRootTransaction(
      db, "user-a", root("user-a", "device-two"), nowMs,
    ),
  ]);

  assert.equal(
    results.filter((item) => item.status === "fulfilled").length,
    1,
  );

  assert.equal(
    results.filter((item) => item.status === "rejected").length,
    1,
  );

  const saved = db.snapshot();

  assert.equal(Object.keys(saved).length, 2);

  const registered = saved[rootPath("user-a")];

  assert.equal(
    saved[ledgerPath("user-a")].deviceId,
    registered.deviceId,
  );

  assert.equal(
    saved[ledgerPath("user-a")].rootFingerprint,
    registered.fingerprint,
  );
});

test("Different UIDs have independent roots", async () => {
  const db = createDb();

  await Promise.all([
    registerFirstRootTransaction(
      db, "user-a", root("user-a", "device-a"), nowMs,
    ),
    registerFirstRootTransaction(
      db, "user-b", root("user-b", "device-b"), nowMs,
    ),
  ]);

  const saved = db.snapshot();

  assert.equal(Object.keys(saved).length, 4);
  assert.equal(saved[rootPath("user-a")].deviceId, "device-a");
  assert.equal(saved[rootPath("user-b")].deviceId, "device-b");
});

test("Failed commit never leaves a partial root", async () => {
  const db = createDb();

  db.failOnce();

  await assert.rejects(
    registerFirstRootTransaction(
      db, "user-a", root("user-a", "device-a"), nowMs,
    ),
    /Simulated atomic commit failure/,
  );

  assert.deepEqual(db.snapshot(), {});
});

test("Transaction rejects account mismatch", async () => {
  const db = createDb();

  await assert.rejects(
    registerFirstRootTransaction(
      db, "user-a", root("user-b", "device-b"), nowMs,
    ),
    (error) => error.code === "invalid-argument",
  );

  assert.deepEqual(db.snapshot(), {});
});

test("Transaction rejects an invalid timestamp", async () => {
  const db = createDb();

  await assert.rejects(
    registerFirstRootTransaction(
      db, "user-a", root("user-a", "device-a"), NaN,
    ),
    (error) => error.code === "invalid-argument",
  );

  assert.deepEqual(db.snapshot(), {});
});
