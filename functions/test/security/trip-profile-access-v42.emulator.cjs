"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("node:crypto");

const {initializeApp, deleteApp} =
  require("firebase-admin/app");
const {getFirestore} =
  require("firebase-admin/firestore");

const PROJECT = "demo-amaterasu-v42";
const EXPECTED_HOST = "127.0.0.1:18080";

// Never allow this test to initialise a production database.
if (process.env.GCLOUD_PROJECT !== PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT !== PROJECT ||
    process.env.FIRESTORE_EMULATOR_HOST !== EXPECTED_HOST) {
  throw new Error(
    "V4.2 refused: local demo project and emulator required.",
  );
}

const {requestTripProfileAccess} = require(
  "../../lib/security/trip-profile-access-relay"
);

if (typeof requestTripProfileAccess?.run !== "function") {
  throw new Error(
    "Compiled callable does not expose .run().",
  );
}

let app;
let db;

test.before(async () => {
  app = initializeApp({projectId: PROJECT});
  db = getFirestore(app);

  await db.collection("v42EmulatorProbe")
    .doc("reachable")
    .set({ok: true});
});

test.after(async () => {
  if (app) await deleteApp(app);
});

async function fixture() {
  const id = crypto.randomBytes(10).toString("hex");

  const tripId = `v42_${id}`;
  const uid = `bob_${id}`;
  const profileUid = `alice_${id}`;
  const deviceId = `bobdevice_${id}`;

  const keys = crypto.generateKeyPairSync("ed25519");

  const publicKey = keys.publicKey.export({
    type: "spki",
    format: "der",
  }).subarray(-32).toString("base64");

  const trip = db.collection("trips").doc(tripId);

  const batch = db.batch();

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
    db.collection("e2eeRoots").doc(uid),
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

    const nonce = options.nonce ??
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

    const canonical = Buffer.from(
      JSON.stringify([
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
      ]),
      "utf8",
    );

    proof.signature = crypto.sign(
      null,
      canonical,
      keys.privateKey,
    ).toString("base64");

    return proof;
  }

  function requestData(proof = signedProof()) {
    return {
      tripId,
      profileUid,
      recipientDeviceId: deviceId,
      proof,
    };
  }

  function call(data, context = {}) {
    const auth = context.auth === undefined ?
      {
        uid,
        token: {email_verified: true},
      } :
      context.auth;

    const appCheck = context.app === undefined ?
      {appId: "v42-local-only"} :
      context.app;

    return requestTripProfileAccess.run({
      data,
      auth,
      app: appCheck,
    });
  }

  async function counts() {
    const [requests, nonces, rates] =
      await Promise.all([
        trip.collection("profileAccessRequests").get(),
        trip.collection("profileAccessRequestNonces").get(),
        trip.collection("profileAccessRate").get(),
      ]);

    return {requests, nonces, rates};
  }

  return {
    trip,
    uid,
    profileUid,
    deviceId,
    signedProof,
    requestData,
    call,
    counts,
  };
}

test("V4.2: valid proof commits all three records", async () => {
  const x = await fixture();

  const receipt = await x.call(x.requestData());

  assert.equal(typeof receipt.requestId, "string");

  const saved = await x.counts();

  assert.equal(saved.requests.size, 1);
  assert.equal(saved.nonces.size, 1);
  assert.equal(saved.rates.size, 1);

  const record = saved.requests.docs[0].data();

  assert.equal(record.recipientUid, x.uid);
  assert.equal(record.profileUid, x.profileUid);
  assert.equal(record.status, "pending");
  assert.equal(Object.hasOwn(record, "signature"), false);
  assert.equal(Object.hasOwn(record, "privateKey"), false);
});

test("V4.2: sequential nonce replay is rejected", async () => {
  const x = await fixture();
  const data = x.requestData();

  await x.call(data);

  await assert.rejects(x.call(data));

  const saved = await x.counts();

  assert.equal(saved.requests.size, 1);
  assert.equal(saved.nonces.size, 1);
});

test("V4.2: concurrent replay accepts exactly one", async () => {
  const x = await fixture();
  const data = x.requestData();

  const results = await Promise.allSettled([
    x.call(data),
    x.call(data),
  ]);

  assert.equal(
    results.filter((r) => r.status === "fulfilled").length,
    1,
  );

  assert.equal(
    results.filter((r) => r.status === "rejected").length,
    1,
  );

  const saved = await x.counts();

  assert.equal(saved.requests.size, 1);
  assert.equal(saved.nonces.size, 1);
  assert.equal(saved.rates.size, 1);
});

test("V4.2: different nonce respects rate limit", async () => {
  const x = await fixture();

  await x.call(x.requestData());

  await assert.rejects(
    x.call(x.requestData()),
  );

  const saved = await x.counts();

  assert.equal(saved.requests.size, 1);
  assert.equal(saved.nonces.size, 1);
});

test("V4.2: forged proof creates no request", async () => {
  const x = await fixture();

  const proof = x.signedProof();
  proof.profileUid = "different-profile";

  await assert.rejects(
    x.call(x.requestData(proof)),
  );

  const saved = await x.counts();

  assert.equal(saved.requests.size, 0);
  assert.equal(saved.nonces.size, 0);
});

test("V4.2: deleted membership blocks request", async () => {
  const x = await fixture();

  await x.trip.collection("members")
    .doc(x.uid).delete();

  await assert.rejects(
    x.call(x.requestData()),
  );

  assert.equal(
    (await x.counts()).requests.size,
    0,
  );
});

test("V4.2: removed member UID blocks request", async () => {
  const x = await fixture();

  await x.trip.update({
    memberUids: [x.profileUid],
  });

  await assert.rejects(
    x.call(x.requestData()),
  );

  assert.equal(
    (await x.counts()).requests.size,
    0,
  );
});

test("V4.2: substituted root device is rejected", async () => {
  const x = await fixture();

  await db.collection("e2eeRoots")
    .doc(x.uid)
    .update({deviceId: "different-device"});

  await assert.rejects(
    x.call(x.requestData()),
  );

  assert.equal(
    (await x.counts()).requests.size,
    0,
  );
});

test("V4.2: expired proof is rejected", async () => {
  const x = await fixture();

  const proof = x.signedProof({
    issuedAtMs: Date.now() - 200000,
  });

  await assert.rejects(
    x.call(x.requestData(proof)),
  );

  assert.equal(
    (await x.counts()).requests.size,
    0,
  );
});

test("V4.2: missing Auth context is rejected", async () => {
  const x = await fixture();

  await assert.rejects(
    x.call(x.requestData(), {auth: null}),
  );

  assert.equal(
    (await x.counts()).requests.size,
    0,
  );
});

test("V4.2: missing App Check context rejected", async () => {
  const x = await fixture();

  await assert.rejects(
    x.call(x.requestData(), {app: null}),
  );

  assert.equal(
    (await x.counts()).requests.size,
    0,
  );
});

test("V4.2: unverified email is rejected", async () => {
  const x = await fixture();

  await assert.rejects(
    x.call(x.requestData(), {
      auth: {
        uid: x.uid,
        token: {email_verified: false},
      },
    }),
  );

  assert.equal(
    (await x.counts()).requests.size,
    0,
  );
});
