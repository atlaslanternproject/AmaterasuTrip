const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const {
  randomBytes,
} = require("node:crypto");

const {
  validateFirstRootRecord,
} = require("../../lib/security/first-root-registration-callable");

const path = process.env.AMATERASU_B1082_FIXTURE;

if (!path) {
  throw new Error("Synthetic Dart fixture path is missing.");
}

const fixture = JSON.parse(fs.readFileSync(path, "utf8"));

function clone() {
  return structuredClone(fixture);
}

function validate(value, uid = fixture.userUid, now = Date.now()) {
  return validateFirstRootRecord(value, uid, now);
}

test("Real Dart Ed25519 signature accepted by TypeScript", () => {
  const verified = validate(clone());

  assert.ok(verified);
  assert.deepStrictEqual(verified, fixture);
});

test("TypeScript rejects another authenticated UID", () => {
  assert.equal(validate(clone(), "other-user"), null);
});

test("TypeScript rejects changed Dart signature", () => {
  const changed = clone();
  const bytes = Buffer.from(changed.signature, "base64");
  bytes[0] ^= 1;
  changed.signature = bytes.toString("base64");

  assert.equal(validate(changed), null);
});

test("TypeScript rejects a changed Dart fingerprint", () => {
  const changed = clone();
  changed.fingerprint = randomBytes(32).toString("base64url");

  assert.equal(validate(changed), null);
});

test("TypeScript rejects swapped Dart signing key", () => {
  const changed = clone();
  changed.ed25519PublicKey = randomBytes(32).toString("base64");

  assert.equal(validate(changed), null);
});

test("TypeScript rejects swapped Dart exchange key", () => {
  const changed = clone();
  changed.x25519PublicKey = randomBytes(32).toString("base64");

  assert.equal(validate(changed), null);
});

test("TypeScript rejects changed device identifier", () => {
  const changed = clone();
  changed.deviceId = randomBytes(32).toString("base64url");

  assert.equal(validate(changed), null);
});

test("TypeScript rejects malformed encrypted envelope", () => {
  const changed = clone();
  changed.recovery.ciphertext = randomBytes(32).toString("base64");

  assert.equal(validate(changed), null);
});

test("TypeScript rejects private-key fields", () => {
  const changed = clone();
  changed.privateKey = "forbidden";

  assert.equal(validate(changed), null);
});

test("TypeScript rejects an expired prepared root", () => {
  const eightDays = 8 * 24 * 60 * 60 * 1000;

  assert.equal(
    validate(clone(), fixture.userUid, fixture.createdAtMs + eightDays),
    null,
  );
});
