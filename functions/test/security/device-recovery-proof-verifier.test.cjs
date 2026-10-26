"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const ts = require("typescript");

function load(filename, resolve = require) {
  const source = fs.readFileSync(
    path.resolve(__dirname, "../../src/security", filename),
    "utf8",
  );

  const compiled = ts.transpileModule(source, {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2020,
    },
  });

  const context = {exports: {}, require: resolve, Buffer};

  vm.runInNewContext(compiled.outputText, context);
  return context.exports;
}

const base = load("device-approval-verifier.ts");

const recovery = load(
  "device-recovery-proof-verifier.ts",
  (name) => name === "./device-approval-verifier" ?
    base : require(name),
);

function publicKey(key) {
  return key.export({
    format: "der",
    type: "spki",
  }).subarray(-32).toString("base64");
}

const now = 1800000000000;

function fixture() {
  const root = crypto.generateKeyPairSync("ed25519");
  const device = crypto.generateKeyPairSync("ed25519");
  const exchange = crypto.generateKeyPairSync("x25519");

  const claim = {
    userUid: "test-user",
    approverDeviceId: "original-device",
    newDeviceId: "new-browser",
    newX25519PublicKey: publicKey(exchange.publicKey),
    newEd25519PublicKey: publicKey(device.publicKey),
    challenge: crypto.randomBytes(32).toString("base64"),
    issuedAtMs: now - 10000,
    expiresAtMs: now + 60000,
  };

  const bytes = base.deviceApprovalSigningBytes(claim);

  const raw = {
    approval: {
      claim,
      signature: crypto.sign(
        null, bytes, root.privateKey,
      ).toString("base64"),
    },
    newDeviceSignature: crypto.sign(
      null, bytes, device.privateKey,
    ).toString("base64"),
  };

  const expected = {
    userUid: claim.userUid,
    approverDeviceId: claim.approverDeviceId,
    newDeviceId: claim.newDeviceId,
    newX25519PublicKey: claim.newX25519PublicKey,
    newEd25519PublicKey: claim.newEd25519PublicKey,
    challenge: claim.challenge,
  };

  return {
    raw,
    expected,
    trusted: publicKey(root.publicKey),
  };
}

test("valid root and device signatures accepted", () => {
  const f = fixture();
  const claim = recovery.verifyRecoveryDeviceProof(
    f.raw, f.trusted, f.expected, now,
  );
  assert.equal(claim.newDeviceId, "new-browser");
});

test("wrong new-device signature rejected", () => {
  const f = fixture();
  const attacker = crypto.generateKeyPairSync("ed25519");
  const bytes = base.deviceApprovalSigningBytes(f.raw.approval.claim);

  f.raw.newDeviceSignature = crypto.sign(
    null, bytes, attacker.privateKey,
  ).toString("base64");

  assert.throws(() => recovery.verifyRecoveryDeviceProof(
    f.raw, f.trusted, f.expected, now,
  ));
});

test("tampered challenge rejected", () => {
  const f = fixture();
  f.raw.approval.claim.challenge =
    crypto.randomBytes(32).toString("base64");

  assert.throws(() => recovery.verifyRecoveryDeviceProof(
    f.raw, f.trusted, f.expected, now,
  ));
});

test("expired proof rejected", () => {
  const f = fixture();

  assert.throws(() => recovery.verifyRecoveryDeviceProof(
    f.raw, f.trusted, f.expected,
    f.raw.approval.claim.expiresAtMs,
  ));
});

test("unexpected payload fields rejected", () => {
  const f = fixture();
  f.raw.extraField = "unexpected";

  assert.throws(() => recovery.verifyRecoveryDeviceProof(
    f.raw, f.trusted, f.expected, now,
  ));
});
