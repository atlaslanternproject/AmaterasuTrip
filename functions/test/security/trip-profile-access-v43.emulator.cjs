"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("node:crypto");

const {initializeApp, deleteApp} =
  require("firebase-admin/app");
const {getFirestore} =
  require("firebase-admin/firestore");
const {getAuth} =
  require("firebase-admin/auth");

const PROJECT = "demo-amaterasu-v43";
const HOST = "127.0.0.1";

const FIRESTORE = `${HOST}:18080`;
const AUTH = `${HOST}:19099`;

if (process.env.GCLOUD_PROJECT !== PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT !== PROJECT ||
    process.env.FIRESTORE_EMULATOR_HOST !== FIRESTORE ||
    process.env.FIREBASE_AUTH_EMULATOR_HOST !== AUTH) {
  throw new Error(
    "V4.3 requires local demo emulators only.",
  );
}

const CALLABLE_URL =
  `http://${HOST}:15001/${PROJECT}` +
  "/europe-west1/requestTripProfileAccess";

const AUTH_URL =
  `http://${AUTH}` +
  "/identitytoolkit.googleapis.com/v1/" +
  "accounts:signInWithPassword?key=local-test-key";

const PASSWORD = "V43_Local_Test_Password_2026!";

let firebaseApp;
let firestore;
let auth;

test.before(async () => {
  firebaseApp = initializeApp({projectId: PROJECT});
  firestore = getFirestore(firebaseApp);
  auth = getAuth(firebaseApp);

  const probe = firestore
    .collection("v43EmulatorProbe")
    .doc("reachable");

  await probe.set({local: true});

  assert.equal((await probe.get()).data().local, true);
});

test.after(async () => {
  if (firebaseApp) await deleteApp(firebaseApp);
});

async function createFixture(options = {}) {
  const suffix =
    crypto.randomBytes(9).toString("hex");

  const tripId = `v43_${suffix}`;
  const uid = `bob_${suffix}`;
  const profileUid = `alice_${suffix}`;
  const deviceId = `device_${suffix}`;
  const email = `bob_${suffix}@example.test`;

  const keys =
    crypto.generateKeyPairSync("ed25519");

  const publicKey = keys.publicKey.export({
    format: "der",
    type: "spki",
  }).subarray(-32).toString("base64");

  await auth.createUser({
    uid,
    email,
    password: PASSWORD,
    emailVerified: options.verified !== false,
  });

  const loginResponse = await fetch(AUTH_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      email,
      password: PASSWORD,
      returnSecureToken: true,
    }),
  });

  const login = await loginResponse.json();

  assert.equal(
    loginResponse.status,
    200,
    JSON.stringify(login),
  );

  assert.equal(typeof login.idToken, "string");

  const trip = firestore.collection("trips").doc(tripId);
  const batch = firestore.batch();

  batch.set(trip, {
    ownerUid: profileUid,
    memberUids: [profileUid, uid],
  });

  batch.set(
    trip.collection("members").doc(profileUid),
    {uid: profileUid},
  );

  batch.set(
    trip.collection("members").doc(uid),
    {uid},
  );

  batch.set(
    firestore.collection("e2eeRoots").doc(uid),
    {
      userUid: uid,
      deviceId,
      ed25519PublicKey: publicKey,
    },
  );

  await batch.commit();

  function signedProof(options = {}) {
    const issuedAtMs =
      options.issuedAtMs ?? Date.now();

    const nonce =
      crypto.randomBytes(32).toString("base64url");

    const proof = {
      uid,
      tripId,
      profileUid,
      deviceId,
      nonce,
      issuedAtMs,
      expiresAtMs: issuedAtMs + 120000,
    };

    const bytes = Buffer.from(JSON.stringify([
      "amaterasutrip",
      "trip-profile-access-request",
      1,
      uid,
      tripId,
      profileUid,
      deviceId,
      nonce,
      issuedAtMs,
      proof.expiresAtMs,
    ]), "utf8");

    proof.signature = crypto.sign(
      null,
      bytes,
      keys.privateKey,
    ).toString("base64");

    return proof;
  }

  function requestBody(proof = signedProof()) {
    return {
      tripId,
      profileUid,
      recipientDeviceId: deviceId,
      proof,
    };
  }

  async function invoke(data = requestBody(), options = {}) {
    const headers = {
      "Content-Type": "application/json",
    };

    if (!options.noAuth) {
      headers.Authorization =
        `Bearer ${options.token ?? login.idToken}`;
    }

    if (!options.noAppCheck) {
      // LOCAL PLACEHOLDER ONLY.
      // This is NOT an authentic attestation token.
      headers["X-Firebase-AppCheck"] =
        "v43-local-emulator-placeholder";
    }

    const response = await fetch(CALLABLE_URL, {
      method: "POST",
      headers,
      body: JSON.stringify({data}),
    });

    const result = await response.json();

    return {
      status: response.status,
      result,
    };
  }

  async function counts() {
    const [requests, nonces, rate] =
      await Promise.all([
        trip.collection("profileAccessRequests").get(),
        trip.collection("profileAccessRequestNonces").get(),
        trip.collection("profileAccessRate").get(),
      ]);

    return [
      requests.size,
      nonces.size,
      rate.size,
    ];
  }

  return {
    trip,
    uid,
    profileUid,
    token: login.idToken,
    signedProof,
    requestBody,
    invoke,
    counts,
  };
}

function succeeded(response) {
  return response.status === 200 &&
    typeof response.result?.result?.requestId === "string";
}

test("HTTP: verified identity creates one request", async () => {
  const x = await createFixture();
  const result = await x.invoke();

  assert.ok(succeeded(result), JSON.stringify(result));
  assert.deepEqual(await x.counts(), [1, 1, 1]);
});

test("HTTP: missing Auth is rejected", async () => {
  const x = await createFixture();

  const result = await x.invoke(
    x.requestBody(),
    {noAuth: true},
  );

  assert.notEqual(result.status, 200);
  assert.deepEqual(await x.counts(), [0, 0, 0]);
});

test("HTTP: unverified email is rejected", async () => {
  const x = await createFixture({verified: false});

  const result = await x.invoke();

  assert.notEqual(result.status, 200);
  assert.deepEqual(await x.counts(), [0, 0, 0]);
});

test("HTTP: missing App Check header rejected", async () => {
  const x = await createFixture();

  const result = await x.invoke(
    x.requestBody(),
    {noAppCheck: true},
  );

  assert.notEqual(result.status, 200);
  assert.deepEqual(await x.counts(), [0, 0, 0]);
});

test("HTTP: another account cannot impersonate device", async () => {
  const alice = await createFixture();
  const bob = await createFixture();

  const result = await alice.invoke(
    alice.requestBody(),
    {token: bob.token},
  );

  assert.notEqual(result.status, 200);
  assert.deepEqual(await alice.counts(), [0, 0, 0]);
});

test("HTTP: sequential replay rejected", async () => {
  const x = await createFixture();
  const body = x.requestBody();

  assert.ok(succeeded(await x.invoke(body)));

  const repeated = await x.invoke(body);

  assert.notEqual(repeated.status, 200);
  assert.deepEqual(await x.counts(), [1, 1, 1]);
});

test("HTTP: concurrent replay commits once", async () => {
  const x = await createFixture();
  const body = x.requestBody();

  const results = await Promise.all([
    x.invoke(body),
    x.invoke(body),
  ]);

  assert.equal(
    results.filter(succeeded).length,
    1,
    JSON.stringify(results),
  );

  assert.deepEqual(await x.counts(), [1, 1, 1]);
});

test("HTTP: removed member rejected", async () => {
  const x = await createFixture();

  await x.trip.update({
    memberUids: [x.profileUid],
  });

  const result = await x.invoke();

  assert.notEqual(result.status, 200);
  assert.deepEqual(await x.counts(), [0, 0, 0]);
});

test("HTTP: tampered signature rejected", async () => {
  const x = await createFixture();
  const proof = x.signedProof();

  proof.profileUid = "another-profile";

  const result = await x.invoke(x.requestBody(proof));

  assert.notEqual(result.status, 200);
  assert.deepEqual(await x.counts(), [0, 0, 0]);
});

test("HTTP: expired proof rejected", async () => {
  const x = await createFixture();

  const proof = x.signedProof({
    issuedAtMs: Date.now() - 180000,
  });

  const result = await x.invoke(x.requestBody(proof));

  assert.notEqual(result.status, 200);
  assert.deepEqual(await x.counts(), [0, 0, 0]);
});
