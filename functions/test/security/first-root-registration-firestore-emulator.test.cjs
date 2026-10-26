const test = require("node:test");
const assert = require("node:assert/strict");
const {randomBytes} = require("node:crypto");

const {initializeApp, deleteApp} =
  require("firebase-admin/app");

const {getFirestore} =
  require("firebase-admin/firestore");

const {registerFirstRootTransaction} =
  require("../../lib/security/first-root-registration-transaction");

const PROJECT = "demo-amaterasu-b1084";
const host = process.env.FIRESTORE_EMULATOR_HOST;

if (!host ||
    !/^(127\.0\.0\.1|localhost):[0-9]+$/.test(host)) {
  throw new Error(
    "FIRESTORE EMULATOR ONLY: emulator host missing.",
  );
}

if (process.env.GCLOUD_PROJECT !== PROJECT) {
  throw new Error(
    "FIRESTORE EMULATOR ONLY: wrong project ID.",
  );
}

const app = initializeApp(
  {projectId: PROJECT},
  "amaterasu-b1084-test",
);

const db = getFirestore(app);

const suffix = randomBytes(8).toString("hex");

function uid(name) {
  return `b1084_${name}_${suffix}`;
}

function root(userUid, deviceId) {
  return {
    version: 1,
    userUid,
    deviceId,
    fingerprint: `synthetic-fingerprint-${deviceId}`,
    testOnly: true,
  };
}

function rootRef(userUid) {
  return db.collection("e2eeRoots").doc(userUid);
}

function ledgerRef(userUid) {
  return db.collection(
    "e2eeRootCreationLedgerV1",
  ).doc(userUid);
}

const nowMs = Date.now();

test("Real Firestore transaction creates both records", async () => {
  const userUid = uid("first");
  const candidate = root(userUid, "device-one");

  await registerFirstRootTransaction(
    db, userUid, candidate, nowMs,
  );

  const [savedRoot, savedLedger] = await Promise.all([
    rootRef(userUid).get(),
    ledgerRef(userUid).get(),
  ]);

  assert.equal(savedRoot.exists, true);
  assert.equal(savedLedger.exists, true);
  assert.deepStrictEqual(savedRoot.data(), candidate);
  assert.equal(
    savedLedger.data().deviceId,
    candidate.deviceId,
  );
  assert.equal(
    savedLedger.data().rootFingerprint,
    candidate.fingerprint,
  );
});

test("Duplicate registration preserves original root", async () => {
  const userUid = uid("duplicate");
  const initial = root(userUid, "original-device");

  await registerFirstRootTransaction(
    db, userUid, initial, nowMs,
  );

  await assert.rejects(
    registerFirstRootTransaction(
      db, userUid, root(userUid, "different-device"), nowMs,
    ),
    (error) => error.code === "already-exists",
  );

  const [savedRoot, savedLedger] = await Promise.all([
    rootRef(userUid).get(),
    ledgerRef(userUid).get(),
  ]);

  assert.deepStrictEqual(savedRoot.data(), initial);
  assert.equal(
    savedLedger.data().deviceId,
    "original-device",
  );
});

test("Existing root without ledger blocks new registration", async () => {
  const userUid = uid("rootonly");

  await rootRef(userUid).create(
    root(userUid, "old-device"),
  );

  await assert.rejects(
    registerFirstRootTransaction(
      db, userUid, root(userUid, "new-device"), nowMs,
    ),
    (error) => error.code === "already-exists",
  );

  const ledger = await ledgerRef(userUid).get();

  assert.equal(ledger.exists, false);
});

test("Historical ledger blocks creation even without root", async () => {
  const userUid = uid("ledgeronly");

  await ledgerRef(userUid).create({
    version: 1,
    userUid,
    deviceId: "historic-device",
    rootFingerprint: "historic-fingerprint",
    registeredAtMs: nowMs - 1000,
  });

  await assert.rejects(
    registerFirstRootTransaction(
      db, userUid, root(userUid, "new-device"), nowMs,
    ),
    (error) => error.code === "already-exists",
  );

  const saved = await rootRef(userUid).get();

  assert.equal(saved.exists, false);
});

test("Concurrent Firestore requests register one root only", async () => {
  const userUid = uid("concurrent");

  const results = await Promise.allSettled([
    registerFirstRootTransaction(
      db, userUid, root(userUid, "device-alpha"), nowMs,
    ),
    registerFirstRootTransaction(
      db, userUid, root(userUid, "device-beta"), nowMs,
    ),
  ]);

  const succeeded = results.filter(
    (result) => result.status === "fulfilled",
  );

  const failed = results.filter(
    (result) => result.status === "rejected",
  );

  assert.equal(succeeded.length, 1);
  assert.equal(failed.length, 1);

  const [savedRoot, savedLedger] = await Promise.all([
    rootRef(userUid).get(),
    ledgerRef(userUid).get(),
  ]);

  assert.equal(savedRoot.exists, true);
  assert.equal(savedLedger.exists, true);

  assert.equal(
    savedRoot.data().deviceId,
    savedLedger.data().deviceId,
  );

  assert.equal(
    savedRoot.data().fingerprint,
    savedLedger.data().rootFingerprint,
  );
});

test("Different accounts can initialise independently", async () => {
  const firstUid = uid("independent_a");
  const secondUid = uid("independent_b");

  await Promise.all([
    registerFirstRootTransaction(
      db, firstUid, root(firstUid, "device-a"), nowMs,
    ),
    registerFirstRootTransaction(
      db, secondUid, root(secondUid, "device-b"), nowMs,
    ),
  ]);

  const [first, second] = await Promise.all([
    rootRef(firstUid).get(),
    rootRef(secondUid).get(),
  ]);

  assert.equal(first.exists, true);
  assert.equal(second.exists, true);
  assert.equal(first.data().deviceId, "device-a");
  assert.equal(second.data().deviceId, "device-b");
});

test("Account mismatch cannot create documents", async () => {
  const authenticatedUid = uid("mismatch");
  const differentUid = uid("other");

  await assert.rejects(
    registerFirstRootTransaction(
      db,
      authenticatedUid,
      root(differentUid, "device-other"),
      nowMs,
    ),
    (error) => error.code === "invalid-argument",
  );

  const [savedRoot, savedLedger] = await Promise.all([
    rootRef(authenticatedUid).get(),
    ledgerRef(authenticatedUid).get(),
  ]);

  assert.equal(savedRoot.exists, false);
  assert.equal(savedLedger.exists, false);
});

test("Invalid transaction timestamp cannot create records", async () => {
  const userUid = uid("badtime");

  await assert.rejects(
    registerFirstRootTransaction(
      db,
      userUid,
      root(userUid, "device-time"),
      Number.NaN,
    ),
    (error) => error.code === "invalid-argument",
  );

  const [savedRoot, savedLedger] = await Promise.all([
    rootRef(userUid).get(),
    ledgerRef(userUid).get(),
  ]);

  assert.equal(savedRoot.exists, false);
  assert.equal(savedLedger.exists, false);
});

test("Firestore emulator test environment is isolated", () => {
  assert.equal(
    process.env.GCLOUD_PROJECT,
    PROJECT,
  );

  assert.match(
    process.env.FIRESTORE_EMULATOR_HOST,
    /^(127\.0\.0\.1|localhost):[0-9]+$/,
  );
});

test.after(async () => {
  await deleteApp(app);
});
