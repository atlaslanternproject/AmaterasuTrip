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

/**
 * B8.4: automatic historical rate lock with a simulated provider.
 * The real handler runs in this process (callable.run), so the global
 * fetch can be replaced: no request ever reaches the internet.
 * Requires `npm run build` (compiled functions/lib).
 */
async function automaticFxScenarios(foreignSnapshot, dated) {
  const {ensureBudgetExpenseFx} = require("../lib/budget/budget-fx.js");
  const realFetch = globalThis.fetch;
  const providerCalls = [];
  let reply = null;
  globalThis.fetch = async (input, init) => {
    const url = String(input);
    if (!url.includes("api.frankfurter.dev")) {
      return realFetch(input, init);
    }
    providerCalls.push(url);
    if (reply instanceof Error) throw reply;
    return new Response(JSON.stringify(reply.body), {status: reply.status});
  };
  const expenses = db.collection("trips").doc(tripId)
    .collection("budgetSharedExpenses");
  const lock = (expenseId, uid = uidA) => ensureBudgetExpenseFx.run({
    auth: {uid, token: {email_verified: true}},
    data: {tripId, expenseId, visibility: "shared"},
  });
  const expectCode = async (label, code, fn) => {
    try {
      await fn();
    } catch (error) {
      assert.equal(error.code, code, `${label}: ${error.message}`);
      console.log("PASS (rejected):", label, code);
      return;
    }
    assert.fail(`Must reject: ${label}`);
  };
  const create = (expenseId) => callable("createBudgetExpense", tokenA, {
    ...dated, expenseId, snapshot: foreignSnapshot,
  });

  try {
    await create("fxAuto");
    reply = {status: 200, body: {
      base: "JPY", quote: "EUR", rate: 0.0062, date: "2024-02-29"}};
    assert.deepEqual(await lock("fxAuto"), {stored: true, alreadyStored: false});
    const url = new URL(providerCalls.at(-1));
    assert.equal(url.pathname, "/v2/rate/JPY/EUR");
    assert.equal(url.searchParams.get("date"), "2024-02-29");
    const stored = (await expenses.doc("fxAuto").get()).get("fxHistorical");
    assert.equal(stored.rate, 0.0062);
    assert.equal(stored.date, "2024-02-29");
    assert.equal(stored.requestedDate, "2024-02-29");
    assert.equal(stored.source, "Frankfurter");
    assert.equal(stored.manual, false);
    assert.ok(stored.lockedAt);
    console.log("PASS: automatic historical rate locked from provider");

    const before = providerCalls.length;
    reply = {status: 200, body: {
      base: "JPY", quote: "EUR", rate: 9, date: "2024-02-29"}};
    assert.deepEqual(await lock("fxAuto"), {stored: true, alreadyStored: true});
    assert.equal(providerCalls.length, before);
    assert.equal(
      (await expenses.doc("fxAuto").get()).get("fxHistorical.rate"), 0.0062);
    console.log("PASS: locked rate is never replaced automatically");

    await create("fxWeekend");
    reply = {status: 200, body: {
      base: "JPY", quote: "EUR", rate: 0.0061, date: "2024-02-28"}};
    await lock("fxWeekend");
    const weekend = (await expenses.doc("fxWeekend").get()).get("fxHistorical");
    assert.equal(weekend.date, "2024-02-28");
    assert.equal(weekend.requestedDate, "2024-02-29");
    console.log("PASS: earlier provider observation keeps both dates");

    const failures = [
      ["observation after the expense day", "data-loss",
        {status: 200, body: {
          base: "JPY", quote: "EUR", rate: 0.006, date: "2024-03-01"}}],
      ["wrong currency pair", "data-loss",
        {status: 200, body: {
          base: "USD", quote: "EUR", rate: 0.9, date: "2024-02-29"}}],
      ["non-positive rate", "data-loss",
        {status: 200, body: {
          base: "JPY", quote: "EUR", rate: 0, date: "2024-02-29"}}],
      ["provider has no rate", "unavailable", {status: 404, body: {}}],
      ["provider unreachable", "unavailable", new Error("offline")],
    ];
    await create("fxMissing");
    for (const [label, code, response] of failures) {
      reply = response;
      await expectCode(label, code, () => lock("fxMissing"));
    }
    assert.equal(
      (await expenses.doc("fxMissing").get()).get("fxHistorical"), undefined);
    console.log("PASS: missing or doubtful rates are never stored");

    const calls = providerCalls.length;
    assert.deepEqual(await lock("shared1"), {stored: false, sameCurrency: true});
    assert.equal(providerCalls.length, calls);
    await expectCode("outsider cannot lock a rate", "permission-denied",
      () => lock("fxMissing", uidC));
    console.log("PASS: same currency and outsider checks");
  } finally {
    globalThis.fetch = realFetch;
  }
}

let tokenA = "";

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
  tokenA = a;

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

  const dated = {
    tripId, expenseId: "backdated", visibility: "shared",
    expenseDate: "2024-02-29", snapshot: paidExpense,
    paymentMethods: [{payerUid: uidA, method: "card", minorUnits: 10000,
      accountCurrency: "JPY", accountDebitMinor: 16000}],
  };
  await callable("createBudgetExpense", a, dated);
  const ref = db.collection("trips").doc(tripId)
    .collection("budgetSharedExpenses").doc("backdated");
  for (const record of [await ref.get(), await ref.collection("revisions").doc("1").get()]) {
    assert.equal(record.get("expenseDate"), dated.expenseDate);
    assert.equal(record.get("accountPayments")[0].accountDebitMinor, 16000);
    assert.equal(record.get("paymentMethods")[0].accountCurrency, undefined);
    assert.equal(record.get("snapshot.total.minorUnits"), 10000);
  }
  await expectFailure("invalid calendar date", () => callable("createBudgetExpense", a,
    {...dated, expenseId: "invalidDate", expenseDate: "2025-02-29"}));
  await expectFailure("invalid debit", () => callable("createBudgetExpense", a,
    {...dated, expenseId: "invalidDebit", paymentMethods: [{...dated.paymentMethods[0], accountDebitMinor: -1}]}));
  console.log("PASS: effective date, account debit and revision");

  const foreignSnapshot = JSON.parse(JSON.stringify(paidExpense, (key, value) =>
    key === "currency" ? "JPY" : value));
  await callable("createBudgetExpense", a, {
    ...dated, expenseId: "foreign", snapshot: foreignSnapshot,
  });
  const foreign = ref.parent.doc("foreign");
  const adjustment = {tripId, expenseId: "foreign", visibility: "shared",
    rate: 0.006, reason: "Verified statement"};
  await expectFailure("participant cannot change another author's rate", () =>
    callable("overrideBudgetExpenseFx", b, adjustment));
  await callable("overrideBudgetExpenseFx", a, adjustment);
  await callable("overrideBudgetExpenseFx", a, {...adjustment, rate: 0.007});
  const locked = (await foreign.get()).get("fxHistorical");
  assert.equal(locked.date, "2024-02-29");
  assert.equal(locked.requestedDate, "2024-02-29");
  assert.equal(locked.source, "Manual");
  assert.equal(locked.rate, 0.007);
  assert.equal((await foreign.get()).get("snapshot.total.minorUnits"), 10000);
  const audit = await foreign.collection("fxRateChanges").orderBy("createdAt").get();
  assert.equal(audit.size, 2);
  assert.equal(audit.docs[1].get("previous.rate"), 0.006);
  assert.equal(audit.docs[1].get("actorUid"), uidA);
  console.log("PASS: manual historical rate, scope and audit");

  await automaticFxScenarios(foreignSnapshot, dated);

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

  await expectFailure("B8.3 invalid method total", () =>
    callable("requestBudgetReimbursement", b, {
      tripId,
      expenseId: "shared1",
      refundId: "invalidMethodTotal",
      creditorUid: uidA,
      minorUnits: 500,
      paymentMethods: [
        {payerUid: uidB, method: "cash", minorUnits: 400},
      ],
    }),
  );

  await expectFailure("B8.3 forged payer", () =>
    callable("requestBudgetReimbursement", b, {
      tripId,
      expenseId: "shared1",
      refundId: "forgedMethodPayer",
      creditorUid: uidA,
      minorUnits: 500,
      paymentMethods: [
        {payerUid: uidA, method: "cash", minorUnits: 500},
      ],
    }),
  );

  await expectFailure("B8.3 unknown method", () =>
    callable("requestBudgetReimbursement", b, {
      tripId,
      expenseId: "shared1",
      refundId: "unknownMethod",
      creditorUid: uidA,
      minorUnits: 500,
      paymentMethods: [
        {payerUid: uidB, method: "crypto", minorUnits: 500},
      ],
    }),
  );

  await expectFailure("B8.3 missing other label", () =>
    callable("requestBudgetReimbursement", b, {
      tripId,
      expenseId: "shared1",
      refundId: "missingOtherLabel",
      creditorUid: uidA,
      minorUnits: 500,
      paymentMethods: [
        {payerUid: uidB, method: "other", minorUnits: 500},
      ],
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

  await callable("requestBudgetReimbursement", b, {
    tripId,
    expenseId: "shared1",
    refundId: "splitReimbursement",
    creditorUid: uidA,
    minorUnits: 2000,
    paymentMethods: [
      {payerUid: uidB, method: "cash", minorUnits: 800},
      {payerUid: uidB, method: "bankTransfer", minorUnits: 1200},
    ],
  });

  const splitRef = db.collection("trips").doc(tripId)
    .collection("budgetSharedExpenses").doc("shared1")
    .collection("reimbursements").doc("splitReimbursement");

  const pendingSplit = await splitRef.get();
  assert.equal(pendingSplit.data().status, "pending");
  assert.deepEqual(pendingSplit.data().paymentMethods, [
    {payerUid: uidB, method: "cash", minorUnits: 800},
    {payerUid: uidB, method: "bankTransfer", minorUnits: 1200},
  ]);

  await callable("confirmBudgetReimbursement", a, {
    tripId,
    expenseId: "shared1",
    refundId: "splitReimbursement",
    approved: true,
  });

  const confirmedSplit = await splitRef.get();
  assert.equal(confirmedSplit.data().status, "confirmed");
  assert.deepEqual(
    confirmedSplit.data().paymentMethods,
    pendingSplit.data().paymentMethods,
  );
  console.log("PASS: B8.3 split reimbursement and recipient approval");

  await expectFailure("financial revision after reimbursement", () =>
    callable("proposeBudgetRevision", a, {
      tripId,
      expenseId: "shared1",
      proposalId: "blockedRevision",
      snapshot: paidExpense,
    }),
  );

  const pair = {tripId, expenseId: "backdated", refundId: "declined", creditorUid: uidA, minorUnits: 900};
  await callable("requestBudgetReimbursement", b, pair);
  await callable("confirmBudgetReimbursement", a, {...pair, approved: false});
  const declined = (await ref.collection("reimbursements").doc("declined").get()).data();
  assert.equal(declined.status, "rejected");
  assert.equal(declined.decidedByUid, uidA);
  assert.ok(declined.decidedAt && declined.createdAt);
  assert.deepEqual((await ref.get()).get("snapshot"), paidExpense);
  await db.collection("trips").doc(tripId).update({memberUids: [uidA]});
  await expectFailure("former debtor cannot request", () =>
    callable("requestBudgetReimbursement", b, {...pair, refundId: "afterExit"}));
  assert.deepEqual((await ref.get()).get("snapshot"), paidExpense);
  assert.equal((await ref.collection("reimbursements").doc("declined").get()).get("status"), "rejected");
  console.log("PASS: rejection, financial history and membership revocation");
  console.log("ALL BACKEND INTEGRATION SCENARIOS PASSED");
}

run().catch((error) => {
  console.error("BUDGET BACKEND INTEGRATION FAILED:", error);
  process.exitCode = 1;
});
