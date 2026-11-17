"use strict";

const assert = require("node:assert/strict");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore} = require("firebase-admin/firestore");

const projectId = process.env.GCLOUD_PROJECT ||
  "demo-amaterasu-budget-privacy";

if (!projectId.startsWith("demo-") ||
    !process.env.FIRESTORE_EMULATOR_HOST ||
    !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Isolated demo project and emulators required.");
}

initializeApp({projectId});

const db = getFirestore();
const auth = getAuth();

const host = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const root = `http://${host}/v1/projects/${projectId}/databases/(default)/documents`;

const trip = "privacyGateTrip";
const owner = "privacyOwner";
const member = "privacyMember";
const outsider = "privacyOutsider";
const password = "Local-Privacy-Test-2026!";

const path = (suffix) => `${root}/trips/${trip}/${suffix}`;

async function login(email) {
  const response = await fetch(
    `http://${authHost}/identitytoolkit.googleapis.com/v1/` +
      "accounts:signInWithPassword?key=demo",
    {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        email,
        password,
        returnSecureToken: true,
      }),
    },
  );

  const data = await response.json();
  assert.equal(response.status, 200, JSON.stringify(data));
  return data.idToken;
}

async function request(token, url, method = "GET", body) {
  const response = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  return {
    status: response.status,
    body: await response.text(),
  };
}

async function allowed(label, token, url, method, body) {
  const response = await request(token, url, method, body);
  assert.ok(
    response.status >= 200 && response.status < 300,
    `${label}: expected allow, got ${response.status} ${response.body}`,
  );
  console.log("PASS:", label);
}

async function denied(label, token, url, method, body) {
  const response = await request(token, url, method, body);
  assert.equal(
    response.status,
    403,
    `${label}: expected 403, got ${response.status} ${response.body}`,
  );
  console.log("PASS (denied):", label);
}

async function run() {
  for (const [uid, email] of [
    [owner, "privacy-owner@example.test"],
    [member, "privacy-member@example.test"],
    [outsider, "privacy-outsider@example.test"],
  ]) {
    await auth.createUser({
      uid,
      email,
      password,
      emailVerified: true,
    });
  }

  const [a, b, c] = await Promise.all([
    login("privacy-owner@example.test"),
    login("privacy-member@example.test"),
    login("privacy-outsider@example.test"),
  ]);

  const tripRef = db.collection("trips").doc(trip);
  await tripRef.set({
    ownerUid: owner,
    memberUids: [owner, member],
    status: "active",
    currency: "EUR",
    name: "Privacy test",
  });

  const shared = tripRef.collection("budgetSharedExpenses").doc("sharedOne");
  const privateA = tripRef.collection("budgetPrivateOwners").doc(owner)
    .collection("expenses").doc("privateOne");
  const privateB = tripRef.collection("budgetPrivateOwners").doc(member)
    .collection("expenses").doc("privateOne");

  for (const ref of [shared, privateA, privateB]) {
    await ref.set({
      createdByUid: ref === privateB ? member : owner,
      ...(ref === shared ? {participantUids: [owner, member]} : {}),
      visibility: ref === shared ? "shared" : "private",
      status: "planned",
    });
  }

  const sharedUrl = path("budgetSharedExpenses/sharedOne");
  const privateAUrl = path(
    `budgetPrivateOwners/${owner}/expenses/privateOne`,
  );
  const privateBUrl = path(
    `budgetPrivateOwners/${member}/expenses/privateOne`,
  );

  const sharedListUrl = path("budgetSharedExpenses");
  const privateAListUrl = path(
    `budgetPrivateOwners/${owner}/expenses`,
  );
  const privateBListUrl = path(
    `budgetPrivateOwners/${member}/expenses`,
  );

  // Read permissions
  await allowed("owner reads shared", a, sharedUrl);
  await allowed("member reads shared", b, sharedUrl);
  await denied("outsider cannot read shared", c, sharedUrl);

  await allowed("owner reads own private", a, privateAUrl);
  await allowed("member reads own private", b, privateBUrl);
  await denied("member cannot read owner's private", b, privateAUrl);
  await denied("owner cannot read member's private", a, privateBUrl);
  await denied("outsider cannot read private", c, privateBUrl);

  // Query permissions, not just document reads
  await denied("unfiltered shared list is denied", b, sharedListUrl);
  await allowed("member queries own expenses", b, path(":runQuery").replace("/:", ":"), "POST", {
    structuredQuery: {
      from: [{collectionId: "budgetSharedExpenses"}],
      where: {fieldFilter: {field: {fieldPath: "participantUids"},
        op: "ARRAY_CONTAINS", value: {stringValue: member}}},
    },
  });
  await allowed("owner lists own private", a, privateAListUrl);
  await denied("member cannot list owner's private", b, privateAListUrl);
  await denied("owner cannot list member's private", a, privateBListUrl);
  await denied("outsider cannot list shared", c, sharedListUrl);

  // Direct client mutations must be rejected.
  const patch = {
    fields: {
      status: {stringValue: "paid"},
    },
  };

  await denied("client cannot modify shared", a, sharedUrl, "PATCH", patch);
  await denied("client cannot modify private", b, privateBUrl, "PATCH", patch);

  await denied(
    "client cannot create shared",
    a,
    path("budgetSharedExpenses?documentId=forgedOne"),
    "POST",
    {fields: {status: {stringValue: "paid"}}},
  );

  await denied(
    "client cannot delete private",
    b,
    privateBUrl,
    "DELETE",
  );

  await denied(
    "client cannot write revision",
    a,
    path("budgetSharedExpenses/sharedOne/revisions/2"),
    "PATCH",
    patch,
  );

  await denied(
    "client cannot write reimbursement",
    b,
    path("budgetSharedExpenses/sharedOne/reimbursements/forged"),
    "PATCH",
    patch,
  );

  console.log("PASS: client privacy and write protections");

  // Remove membership; existing token must not retain access.
  await tripRef.update({memberUids: [owner]});

  await denied(
    "removed member cannot read shared",
    b,
    sharedUrl,
  );
  await denied(
    "removed member cannot read former private data",
    b,
    privateBUrl,
  );

  console.log("PASS: revoked member protections");
  console.log("ALL BUDGET PRIVACY TESTS PASSED");
}

run().catch((error) => {
  console.error("BUDGET PRIVACY TEST FAILED:", error);
  process.exitCode = 1;
});
