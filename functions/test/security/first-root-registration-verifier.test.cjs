const test = require("node:test");
const assert = require("node:assert/strict");

const {
  randomBytes,
  createHash,
  generateKeyPairSync,
  sign,
} = require("node:crypto");

const {
  validateFirstRootRecord,
} = require("../../lib/security/first-root-registration-callable");

function fixture() {
  const now = Date.now();

  const signing = generateKeyPairSync("ed25519");
  const exchange = generateKeyPairSync("x25519");

  const edPublic = signing.publicKey.export({
    format: "der",
    type: "spki",
  }).subarray(-32).toString("base64");

  const xPublic = exchange.publicKey.export({
    format: "der",
    type: "spki",
  }).subarray(-32).toString("base64");

  const uid = "test-user";

  const deviceId = randomBytes(32).toString("base64url");

  const createdAtMs = now - 1000;

  const canonical = Buffer.from(JSON.stringify([
    "amaterasutrip",
    "first-device-trust-anchor",
    1,
    uid,
    deviceId,
    xPublic,
    edPublic,
    createdAtMs,
  ]));

  const root = {
    version: 1,
    userUid: uid,
    deviceId,
    createdAtMs,
    x25519PublicKey: xPublic,
    ed25519PublicKey: edPublic,
    signature: sign(
      null,
      canonical,
      signing.privateKey,
    ).toString("base64"),
    fingerprint: createHash("sha256")
      .update(canonical)
      .digest("base64url"),
    recovery: {
      version: 1,
      salt: randomBytes(32).toString("base64"),
      nonce: randomBytes(12).toString("base64"),
      ciphertext: randomBytes(64).toString("base64"),
      mac: randomBytes(16).toString("base64"),
    },
  };

  return {root, uid, now};
}

test("valid signed root accepted", () => {
  const {root, uid, now} = fixture();

  assert.ok(
    validateFirstRootRecord(root, uid, now),
  );
});

test("another account rejected", () => {
  const {root, now} = fixture();

  assert.equal(
    validateFirstRootRecord(
      root,
      "different-user",
      now,
    ),
    null,
  );
});

test("changed signature rejected", () => {
  const {root, uid, now} = fixture();

  root.signature = randomBytes(64).toString("base64");

  assert.equal(
    validateFirstRootRecord(root, uid, now),
    null,
  );
});

test("changed fingerprint rejected", () => {
  const {root, uid, now} = fixture();

  root.fingerprint = randomBytes(32).toString("base64url");

  assert.equal(
    validateFirstRootRecord(root, uid, now),
    null,
  );
});

test("changed public key rejected", () => {
  const {root, uid, now} = fixture();

  root.ed25519PublicKey = randomBytes(32).toString("base64");

  assert.equal(
    validateFirstRootRecord(root, uid, now),
    null,
  );
});

test("invalid encrypted recovery envelope rejected", () => {
  const {root, uid, now} = fixture();

  root.recovery.nonce = randomBytes(8).toString("base64");

  assert.equal(
    validateFirstRootRecord(root, uid, now),
    null,
  );
});

test("additional fields rejected", () => {
  const {root, uid, now} = fixture();

  root.privateKey = "must-not-be-accepted";

  assert.equal(
    validateFirstRootRecord(root, uid, now),
    null,
  );
});

test("expired root preparation rejected", () => {
  const {root, uid, now} = fixture();

  assert.equal(
    validateFirstRootRecord(
      root,
      uid,
      now + 8 * 86400000,
    ),
    null,
  );
});

test("a different device identifier is rejected", () => {
  const {root, uid, now} = fixture();

  root.deviceId = randomBytes(32).toString("base64url");

  assert.equal(
    validateFirstRootRecord(root, uid, now),
    null,
  );
});
