"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const ts = require("typescript");

let registrations = 0;
let lastContext = null;

class MockHttpsError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

const source = path.resolve(
  __dirname,
  "../../src/security/recovery-device-enrollment-callable.ts",
);

const compiled = ts.transpileModule(
  fs.readFileSync(source, "utf8"),
  {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2020,
    },
  },
).outputText;

const exported = {};

vm.runInNewContext(compiled, {
  exports: exported,
  Object,
  Date,
  require(name) {
    if (name === "firebase-admin/firestore") {
      return {getFirestore: () => ({})};
    }

    if (name === "firebase-functions/v2/https") {
      return {
        HttpsError: MockHttpsError,
        onCall: (options, callback) => ({options, callback}),
      };
    }

    if (name === "./recovery-device-enrollment-transaction") {
      return {
        RecoveryDeviceEnrollmentTransaction: class {
          async register(context) {
            registrations++;
            lastContext = context;
            return {deviceId: "test-device"};
          }
        },
      };
    }

    throw new Error(`Unexpected import: ${name}`);
  },
});

const endpoint = exported.recoveryDeviceEnrollmentCandidate;
const nowSeconds = Math.floor(Date.now() / 1000);

function call(overrides = {}) {
  return endpoint.callback({
    auth: {
      uid: "test-user",
      token: {
        email_verified: true,
        auth_time: nowSeconds,
      },
    },
    app: {appId: "test-app"},
    data: {proof: {test: true}},
    ...overrides,
  });
}

test("01 - App Check enforced", () => {
  assert.equal(endpoint.options.enforceAppCheck, true);
});

test("02 - Valid authentication forwards correct UID", async () => {
  const before = registrations;

  await call();

  assert.equal(registrations, before + 1);
  assert.equal(lastContext.authenticatedUid, "test-user");
});

test("03 - Missing authentication rejected", async () => {
  await assert.rejects(
    call({auth: null}),
    /login required/,
  );
});

test("04 - Unverified email rejected", async () => {
  await assert.rejects(
    call({
      auth: {
        uid: "test-user",
        token: {
          email_verified: false,
          auth_time: nowSeconds,
        },
      },
    }),
    /login required/,
  );
});

test("05 - Expired login rejected", async () => {
  await assert.rejects(
    call({
      auth: {
        uid: "test-user",
        token: {
          email_verified: true,
          auth_time: nowSeconds - 600,
        },
      },
    }),
    /sign in again/,
  );
});

test("06 - Missing App Check rejected", async () => {
  await assert.rejects(
    call({app: null}),
    /login required/,
  );
});

test("07 - Unexpected payload rejected", async () => {
  await assert.rejects(
    call({data: {proof: {}, unexpected: true}}),
    /Invalid recovery request/,
  );
});
