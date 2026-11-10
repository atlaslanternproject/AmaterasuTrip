"use strict";

const assert = require("node:assert/strict");
const {getApps, initializeApp, deleteApp} =
  require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");

const project = process.env.GCLOUD_PROJECT ||
  "demo-amaterasu-budget";

const host = process.env.FIRESTORE_EMULATOR_HOST;

if (!host) {
  throw new Error("Firestore Emulator is required.");
}

const app = getApps().length ?
  getApps()[0] :
  initializeApp({projectId: project});

const db = getFirestore(app);

function token(uid, verified = true) {
  const now = Math.floor(Date.now() / 1000);
  const encode = (value) =>
    Buffer.from(JSON.stringify(value)).toString("base64url");

  const payload = {
    iss: `https://securetoken.google.com/${project}`,
    aud: project,
    auth_time: now,
    iat: now,
    exp: now + 3600,
    sub: uid,
    user_id: uid,
    email: `${uid}@example.test`,
    email_verified: verified,
    firebase: {sign_in_provider: "password"},
  };

  return [
    encode({alg: "none", typ: "JWT"}),
    encode(payload),
    "",
  ].join(".");
}

const root =
  `http://${host}/v1/projects/${project}` +
  "/databases/(default)/documents";

async function request(method, path, uid, verified = true) {
  const response = await fetch(
    `${root}/${path}`,
    {
      method,
      headers: {
        Authorization: `Bearer ${token(uid, verified)}`,
        "Content-Type": "application/json",
      },
      ...(method === "PATCH" ?
        {body: JSON.stringify({
          fields: {
            currency: {stringValue: "EUR"},
          },
        })} :
        {}),
    }
  );

  return response.status;
}

async function allowed(path, uid) {
  const status = await request("GET", path, uid);
  assert.equal(
    status,
    200,
    `Expected allowed GET for ${uid} at ${path}; got ${status}`
  );
}

async function denied(path, uid) {
  const status = await request("GET", path, uid);
  assert.equal(
    status,
    403,
    `Expected denied GET for ${uid} at ${path}; got ${status}`
  );
}

async function run() {
  const trip = db.collection("trips").doc("budget_test_trip");

  await trip.set({
    ownerUid: "anna",
    memberUids: ["anna", "luca"],
    status: "active",
  });

  await trip.collection("budgetSharedExpenses")
    .doc("hotel")
    .set({createdByUid: "anna", participantUids: ["anna", "luca"], currency: "EUR"});

  await trip.collection("budgetPrivateOwners")
    .doc("anna")
    .collection("expenses")
    .doc("private_anna")
    .set({createdByUid: "anna", currency: "EUR"});

  await trip.collection("budgetPrivateOwners")
    .doc("luca")
    .collection("expenses")
    .doc("private_luca")
    .set({createdByUid: "luca", currency: "EUR"});

  const shared = "trips/budget_test_trip/" +
    "budgetSharedExpenses/hotel";

  const annaPrivate = "trips/budget_test_trip/" +
    "budgetPrivateOwners/anna/expenses/private_anna";

  const lucaPrivate = "trips/budget_test_trip/" +
    "budgetPrivateOwners/luca/expenses/private_luca";

  await allowed(shared, "anna");
  await allowed(shared, "luca");
  await denied(shared, "outsider");

  await allowed(annaPrivate, "anna");
  await denied(annaPrivate, "luca");
  await denied(annaPrivate, "outsider");

  await allowed(lucaPrivate, "luca");
  await denied(lucaPrivate, "anna");

  const writeStatus = await request("PATCH", shared, "anna");
  assert.equal(writeStatus, 403,
    "Direct client financial writes must be denied.");

  await trip.update({
    memberUids: ["anna"],
  });

  await denied(shared, "luca");
  await denied(lucaPrivate, "luca");

  console.log("BUDGET B2.2 SECURITY TESTS PASSED");
}

run()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await deleteApp(app);
  });