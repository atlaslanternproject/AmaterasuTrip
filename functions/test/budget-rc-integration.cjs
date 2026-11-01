"use strict";

const assert = require("node:assert/strict");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore} = require("firebase-admin/firestore");

const projectId = process.env.GCLOUD_PROJECT ||
  process.env.GCLOUD_PROJECT_ID ||
  "demo-amaterasu-budget-rc";

if (!projectId.startsWith("demo-")) {
  throw new Error("Only an isolated demo Firebase project is permitted.");
}

if (!process.env.FIRESTORE_EMULATOR_HOST ||
    !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Firestore and Auth emulators are both required.");
}

initializeApp({projectId});

const db = getFirestore();
const auth = getAuth();

const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const functionsHost = process.env.FIREBASE_FUNCTIONS_EMULATOR_HOST ||
  "127.0.0.1:5001";

const base = `http://${functionsHost}/${projectId}/europe-west1`;
const tripId = "budgetRcTrip";
const uidA = "budgetRcOwner";
const uidB = "budgetRcTraveler";
const uidC = "budgetRcOutsider";

const money = (minorUnits) => ({
  currency: "EUR",
  minorUnits,
});

const paidExpense = {
  total: money(10000),
  status: "paid",
  shares: {
    [uidA]: money(5000),
    [uidB]: money(5000),
  },
  advances: {
    [uidA]: money(10000),
  },
};

async function signIn(email, password) {
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
  const body = await response.json();
  assert.equal(response.status, 200, JSON.stringify(body));
  return body.idToken;
}

async function callable(name, token, data) {
  const response = await fetch(`${base}/${name}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({data}),
  });
  const result = await response.json();
  if (!response.ok || result.error) {
    throw new Error(
      `${name}: ${response.status} ${JSON.stringify(result.error || result)}`,
    );
  }
  return result.result;
}

async function expectFailure(label, fn) {
  let failed = false;
  try {
    await fn();
  } catch (error) {
    failed = true;
    console.log("PASS (rejected):", label, String(error.message).slice(0, 180));
  }
  assert.equal(failed, true, `Must reject: ${label}`);
}

async function run() {
  const password = "LocalTest-Only-2026!";

  for (const [uid, email] of [
    [uidA, "owner@budget-rc.example"],
    [uidB, "member@budget-rc.example"],
    [uidC, "outsider@budget-rc.example"],
  ]) {
    await auth.createUser({
      uid,
      email,
      password,
      emailVerified: true,
    });
  }

  const [a, b, c] = await Promise.all([
    signIn("owner@budget-rc.example", password),
    signIn("member@budget-rc.example", password),
    signIn("outsider@budget-rc.example", password),
  ]);

  await db.collection("trips").doc(tripId).set({
    ownerUid: uidA,
    memberUids: [uidA, uidB],
    status: "active",
    currency: "EUR",
    name: "Budget emulator test",
  });

  console.log("PASS: isolated users and trip");

  await callable("createBudgetExpense", a, {
    tripId,
    expenseId: "shared1",
    visibility: "shared",
    snapshot: paidExpense,
  });
  console.log("PASS: shared expense creation");

  await expectFailure("outsider creates shared expense", () =>
    callable("createBudgetExpense", c, {
      tripId,
      expenseId: "unauthorized1",
      visibility: "shared",
      snapshot: paidExpense,
    }),
  );

  await expectFailure("different payer without approval", () =>
    callable("createBudgetExpense", b, {
      tripId,
      expenseId: "unauthorizedPayer",
      visibility: "shared",
      snapshot: paidExpense,
    }),
  );

  await expectFailure("duplicate expense ID", () =>
    callable("createBudgetExpense", a, {
      tripId,
      expenseId: "shared1",
      visibility: "shared",
      snapshot: paidExpense,
    }),
  );

  await callable("createBudgetExpense", b, {
    tripId,
    expenseId: "privateB",
    visibility: "private",
    snapshot: {
      total: money(2300),
      status: "paid",
      shares: {[uidB]: money(2300)},
      advances: {[uidB]: money(2300)},
    },
  });
  console.log("PASS: private expense creation");

  const privateDoc = await db.collection("trips").doc(tripId)
    .collection("budgetPrivateOwners").doc(uidB)
    .collection("expenses").doc("privateB").get();

  assert.equal(privateDoc.exists, true);

  await expectFailure("reimbursement exceeds original debt", () =>
    callable("requestBudgetReimbursement", b, {
      tripId,
      expenseId: "shared1",
      refundId: "tooLarge",
      creditorUid: uidA,
      minorUnits: 5001,
    }),
  );

  const requests = await Promise.allSettled([
    callable("requestBudgetReimbursement", b, {
      tripId,
      expenseId: "shared1",
      refundId: "concurrent1",
      creditorUid: uidA,
      minorUnits: 3000,
    }),
    callable("requestBudgetReimbursement", b, {
      tripId,
      expenseId: "shared1",
      refundId: "concurrent2",
      creditorUid: uidA,
      minorUnits: 3000,
    }),
  ]);

  const successes = requests.filter((r) => r.status === "fulfilled");
  const failures = requests.filter((r) => r.status === "rejected");

  assert.equal(
    successes.length,
    1,
    "Exactly one concurrent reimbursement must succeed",
  );
  assert.equal(failures.length, 1);
  console.log("PASS: concurrent reimbursement reservation");

  const winningId = requests[0].status === "fulfilled"
    ? "concurrent1" : "concurrent2";

  await expectFailure("debtor confirms own reimbursement", () =>
    callable("confirmBudgetReimbursement", b, {
      tripId,
      expenseId: "shared1",
      refundId: winningId,
      approved: true,
    }),
  );

  await callable("confirmBudgetReimbursement", a, {
    tripId,
    expenseId: "shared1",
    refundId: winningId,
    approved: true,
  });
  console.log("PASS: creditor confirms reimbursement");

  await expectFailure("duplicate confirmation", () =>
    callable("confirmBudgetReimbursement", a, {
      tripId,
      expenseId: "shared1",
      refundId: winningId,
      approved: true,
    }),
  );

  await expectFailure("financial revision after reimbursement", () =>
    callable("proposeBudgetRevision", a, {
      tripId,
      expenseId: "shared1",
      proposalId: "blockedRevision",
      snapshot: paidExpense,
    }),
  );

  console.log("ALL BACKEND INTEGRATION SCENARIOS PASSED");
}

run().catch((error) => {
  console.error("BUDGET BACKEND INTEGRATION FAILED:", error);
  process.exitCode = 1;
});
