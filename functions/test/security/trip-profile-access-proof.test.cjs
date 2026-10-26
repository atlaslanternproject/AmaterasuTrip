const test = require("node:test");
const assert = require("node:assert/strict");
const {generateKeyPairSync, sign} = require("node:crypto");

const {
  verifyTripProfileAccessProof,
} = require("../../lib/security/trip-profile-access-proof");

function fixture() {
  const pair = generateKeyPairSync("ed25519");
  const now = Date.now();
  const nonce = Buffer.alloc(32, 31).toString("base64url");

  const publicKey = pair.publicKey.export({
    type: "spki",
    format: "der",
  }).subarray(-32).toString("base64");

  const proof = {
    uid: "bob",
    tripId: "trip-a",
    profileUid: "alice",
    deviceId: "device-b",
    nonce,
    issuedAtMs: now,
    expiresAtMs: now + 120000,
    signature: "",
  };

  const signedBytes = Buffer.from(JSON.stringify([
    "amaterasutrip",
    "trip-profile-access-request",
    1,
    proof.uid,
    proof.tripId,
    proof.profileUid,
    proof.deviceId,
    nonce,
    proof.issuedAtMs,
    proof.expiresAtMs,
  ]), "utf8");

  proof.signature =
    sign(null, signedBytes, pair.privateKey).toString("base64");

  return {
    proof,
    root: {
      userUid: "bob",
      deviceId: "device-b",
      ed25519PublicKey: publicKey,
    },
    expected: {
      uid: "bob",
      tripId: "trip-a",
      profileUid: "alice",
      deviceId: "device-b",
    },
    now,
  };
}

function validate(x, at = x.now) {
  return verifyTripProfileAccessProof(
    x.proof, x.root, x.expected, at,
  );
}

test("Valid signed proof", () => {
  const x = fixture();
  assert.equal(validate(x).nonce, x.proof.nonce);
});

test("Changed destination rejected", () => {
  const x = fixture();
  x.proof.profileUid = "charlie";
  assert.throws(() => validate(x));
});

test("Another device rejected", () => {
  const x = fixture();
  x.root.deviceId = "other";
  assert.throws(() => validate(x));
});

test("Wrong public signing key rejected", () => {
  const x = fixture();
  x.root.ed25519PublicKey =
    Buffer.alloc(32, 42).toString("base64");
  assert.throws(() => validate(x));
});

test("Expired proof rejected", () => {
  const x = fixture();
  assert.throws(() => validate(x, x.now + 120001));
});

test("Future timestamp rejected", () => {
  const x = fixture();
  assert.throws(() => validate(x, x.now - 30001));
});

test("Modified signature rejected", () => {
  const x = fixture();
  x.proof.signature =
    Buffer.alloc(64, 42).toString("base64");
  assert.throws(() => validate(x));
});

test("Invalid nonce rejected", () => {
  const x = fixture();
  x.proof.nonce = "invalid";
  assert.throws(() => validate(x));
});

test("Unexpected fields rejected", () => {
  const x = fixture();
  x.proof.privateKey = "forbidden";
  assert.throws(() => validate(x));
});
