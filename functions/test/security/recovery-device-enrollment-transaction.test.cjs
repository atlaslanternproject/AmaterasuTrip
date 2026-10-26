"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const ts = require("typescript");

const sourceRoot = path.resolve(
  __dirname, "../../src/security",
);

const moduleCache = new Map();

function load(filename) {
  if (moduleCache.has(filename)) {
    return moduleCache.get(filename);
  }

  const source = fs.readFileSync(
    path.join(sourceRoot, filename), "utf8",
  );

  const compiled = ts.transpileModule(source, {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2020,
    },
  });

  const exported = {};
  moduleCache.set(filename, exported);

  vm.runInNewContext(compiled.outputText, {
    exports: exported,
    Buffer,
    require: (name) => {
      if (name.startsWith("./")) {
        return load(name.slice(2) + ".ts");
      }
      return require(name);
    },
  });

  return exported;
}

const verifier = load("device-approval-verifier.ts");

const {RecoveryDeviceEnrollmentTransaction} = load(
  "recovery-device-enrollment-transaction.ts",
);

const nowMs = 1790000000000;
const uid = "audit-user";

function newId() {
  return crypto.randomBytes(32).toString("base64url");
}

function rawPublic(key) {
  return key.export({
    format: "der",
    type: "spki",
  }).subarray(-32).toString("base64");
}

function fixture() {
  const root = crypto.generateKeyPairSync("ed25519");
  const device = crypto.generateKeyPairSync("ed25519");
  const exchange = crypto.generateKeyPairSync("x25519");
  const rootId = newId();

  const claim = {
    userUid: uid,
    approverDeviceId: rootId,
    newDeviceId: newId(),
    newX25519PublicKey: rawPublic(exchange.publicKey),
    newEd25519PublicKey: rawPublic(device.publicKey),
    challenge: crypto.randomBytes(32).toString("base64"),
    issuedAtMs: nowMs - 1000,
    expiresAtMs: nowMs + 120000,
  };

  const bytes = verifier.deviceApprovalSigningBytes(claim);

  return {
    rootDoc: {
      version: 1,
      userUid: uid,
      deviceId: rootId,
      ed25519PublicKey: rawPublic(root.publicKey),
    },
    proof: {
      approval: {
        claim,
        signature: crypto.sign(
          null, bytes, root.privateKey,
        ).toString("base64"),
      },
      newDeviceSignature: crypto.sign(
        null, bytes, device.privateKey,
      ).toString("base64"),
    },
  };
}

// In-memory Firestore mock.
// Writes are committed together or not at all.
function fakeDb(f) {
  const docs = new Map([
    [`e2eeRoots/${uid}`, f.rootDoc],
  ]);

  function ref(location) {
    return {
      path: location,
      doc: (id) => ref(`${location}/${id}`),
      collection: (id) => ref(`${location}/${id}`),
    };
  }

  const db = {
    collection: (name) => ref(name),

    async runTransaction(callback) {
      const changes = [];

      const tx = {
        get: async (reference) => ({
          exists: docs.has(reference.path),
          data: () => docs.get(reference.path),
        }),

        create(reference, data) {
          changes.push([reference.path, data]);
        },
      };

      const result = await callback(tx);

      if (changes.some(([location]) => docs.has(location))) {
        throw new Error("ALREADY_EXISTS");
      }

      for (const [location, data] of changes) {
        docs.set(location, data);
      }

      return result;
    },
  };

  return {db, docs};
}

test("01 - Valid proof registers device and replay", async () => {
  const f = fixture();
  const {db, docs} = fakeDb(f);

  const service = new RecoveryDeviceEnrollmentTransaction(
    db, () => nowMs,
  );

  const result = await service.register({
    authenticatedUid: uid,
    proof: f.proof,
  });

  assert.equal(result.deviceId, f.proof.approval.claim.newDeviceId);
  assert.equal(docs.size, 3);

  assert.ok(
    docs.has(`e2eeDevices/${uid}/devices/${result.deviceId}`),
  );

  assert.equal(
    [...docs.keys()].filter((key) =>
      key.startsWith("deviceApprovalReplayV1/")
    ).length,
    1,
  );
});

test("02 - Repeated approval rejected", async () => {
  const f = fixture();
  const {db, docs} = fakeDb(f);

  const service = new RecoveryDeviceEnrollmentTransaction(
    db, () => nowMs,
  );

  await service.register({
    authenticatedUid: uid,
    proof: f.proof,
  });

  await assert.rejects(() => service.register({
    authenticatedUid: uid,
    proof: f.proof,
  }));

  assert.equal(docs.size, 3);
});

test("03 - Invalid new-device signature rejected", async () => {
  const f = fixture();
  const {db, docs} = fakeDb(f);

  f.proof.newDeviceSignature =
    crypto.randomBytes(64).toString("base64");

  const service = new RecoveryDeviceEnrollmentTransaction(
    db, () => nowMs,
  );

  await assert.rejects(() => service.register({
    authenticatedUid: uid,
    proof: f.proof,
  }));

  assert.equal(docs.size, 1);
});

test("04 - Different authenticated user rejected", async () => {
  const f = fixture();
  const {db, docs} = fakeDb(f);

  const service = new RecoveryDeviceEnrollmentTransaction(
    db, () => nowMs,
  );

  await assert.rejects(() => service.register({
    authenticatedUid: "another-user",
    proof: f.proof,
  }));

  assert.equal(docs.size, 1);
});

test("05 - Missing trusted root rejected", async () => {
  const f = fixture();
  const {db, docs} = fakeDb(f);

  docs.delete(`e2eeRoots/${uid}`);

  const service = new RecoveryDeviceEnrollmentTransaction(
    db, () => nowMs,
  );

  await assert.rejects(() => service.register({
    authenticatedUid: uid,
    proof: f.proof,
  }));

  assert.equal(docs.size, 0);
});

test("06 - Expired approval rejected", async () => {
  const f = fixture();
  const {db, docs} = fakeDb(f);

  const service = new RecoveryDeviceEnrollmentTransaction(
    db, () => nowMs + 120000,
  );

  await assert.rejects(() => service.register({
    authenticatedUid: uid,
    proof: f.proof,
  }));

  assert.equal(docs.size, 1);
});
