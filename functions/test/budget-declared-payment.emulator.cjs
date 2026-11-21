"use strict";

// "Segna come pagato": test con emulatori (Firestore, Auth, Functions)
// di declareBudgetPayment e voidBudgetPayment insieme alle funzioni
// esistenti (rimborsi, chiusura debiti degli ex membri, storico).
// Uso: vedi tool/check_all.sh (emu_declared_payment).

const assert = require("node:assert/strict");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore} = require("firebase-admin/firestore");

const projectId = process.env.GCLOUD_PROJECT || "demo-amaterasu-budget-paid";
if (!projectId.startsWith("demo-") ||
    !process.env.FIRESTORE_EMULATOR_HOST ||
    !process.env.FIREBASE_AUTH_EMULATOR_HOST ||
    !process.env.FIREBASE_FUNCTIONS_EMULATOR_HOST) {
  throw new Error("STOP: demo project and local emulators required.");
}

initializeApp({projectId});
const db = getFirestore();
const auth = getAuth();

const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const base = `http://${process.env.FIREBASE_FUNCTIONS_EMULATOR_HOST}/` +
  `${projectId}/europe-west1`;
const tripId = "paidTrip";
const A = "paidCreditor";
const B = "paidDebtor";
const C = "paidOutsider";
const D = "paidFormer";
const tokens = {};
let seq = 0;
const newId = (prefix) => `${prefix}${++seq}x${Date.now()}`;

const money = (minorUnits) => ({currency: "EUR", minorUnits});

/** A paid 100 EUR; B (and optionally D) owe 50 EUR each to A. */
function snapshot(withD) {
  const shares = {[A]: money(withD ? 5000 : 5000), [B]: money(5000)};
  if (withD) shares[D] = money(5000);
  return {
    total: money(withD ? 15000 : 10000),
    status: "paid",
    shares,
    advances: {[A]: money(withD ? 15000 : 10000)},
  };
}

async function signIn(email, password) {
  const response = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/` +
    "accounts:signInWithPassword?key=demo", {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({email, password, returnSecureToken: true}),
  });
  const body = await response.json();
  assert.equal(response.status, 200, JSON.stringify(body));
  return body.idToken;
}

async function call(name, who, data) {
  const response = await fetch(`${base}/${name}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${tokens[who]}`,
    },
    body: JSON.stringify({data: {tripId, ...data}}),
  });
  const body = await response.json();
  if (!response.ok || body.error) {
    const error = new Error(`${name}: ${JSON.stringify(body.error || body)}`);
    error.status = body.error?.status;
    error.serverMessage = body.error?.message;
    throw error;
  }
  return body.result;
}

async function rejects(label, status, message, fn) {
  try {
    await fn();
  } catch (error) {
    assert.equal(error.status, status, `${label}: ${error.message}`);
    if (message) assert.equal(error.serverMessage, message, label);
    console.log("PASS (rejected):", label, "-", status, error.serverMessage);
    return;
  }
  assert.fail(`Must reject: ${label}`);
}

async function createExpense(withD = false) {
  const id = newId("exp");
  await db.collection("trips").doc(tripId)
    .collection("budgetSharedExpenses").doc(id).set({
      title: "Hotel " + id,
      snapshot: snapshot(withD),
      participantUids: withD ? [A, B, D] : [A, B],
      participantNames: {[A]: "Anna", [B]: "Bruno", [D]: "Dario"},
      version: 1,
      lifecycle: "active",
    });
  return id;
}

const refunds = (expenseId) => db.collection("trips").doc(tripId)
  .collection("budgetSharedExpenses").doc(expenseId)
  .collection("reimbursements");

const declare = (who, expenseId, debtorUid, minorUnits, extra = {}) =>
  call("declareBudgetPayment", who, {
    expenseId, refundId: newId("pay"), debtorUid, minorUnits, ...extra,
  });

async function setup() {
  const password = "LocalTest-Only-2026!";
  for (const uid of [A, B, C, D]) {
    await auth.createUser({
      uid, email: `${uid}@paid.example`, password, emailVerified: true,
    });
    tokens[uid] = await signIn(`${uid}@paid.example`, password);
  }
  await db.collection("trips").doc(tripId).set({
    ownerUid: A, memberUids: [A, B, D], status: "active",
    currency: "EUR", name: "Declared payments",
  });
  console.log("PASS: isolated users and trip");
}

async function creditorRecords() {
  const expenseId = await createExpense();
  const result = await declare(A, expenseId, B, 2000, {
    paidOn: "2026-11-01", note: "Contanti al bar",
    paymentMethods: [{payerUid: B, method: "cash", minorUnits: 2000}],
  });
  assert.equal(result.declared, true);
  assert.equal(result.remainingMinor, 3000);
  const docs = (await refunds(expenseId).get()).docs.map((d) => d.data());
  assert.equal(docs.length, 1);
  const record = docs[0];
  assert.equal(record.kind, "declared");
  assert.equal(record.origin, "creditor");
  assert.equal(record.status, "confirmed");
  assert.equal(record.recordedByUid, A);
  assert.equal(record.debtorUid, B);
  assert.equal(record.creditorUid, A);
  assert.equal(record.paidOn, "2026-11-01");
  assert.equal(record.note, "Contanti al bar");
  assert.equal(record.paymentMethods[0].method, "cash");
  console.log("PASS: creditor records a payment (confirmed, origin creditor)");

  const today = await declare(A, expenseId, B, 500);
  assert.equal(today.remainingMinor, 2500);
  const latest = (await refunds(expenseId).get()).docs.map((d) => d.data())
    .find((d) => d.minorUnits === 500);
  assert.match(latest.paidOn, /^\d{4}-\d{2}-\d{2}$/);
  assert.equal(latest.note, undefined);
  console.log("PASS: date defaults to today, note optional");

  await rejects("debtor cannot declare for the creditor", "PERMISSION_DENIED",
    "Creditor only.", () => declare(B, expenseId, A, 100));
  await rejects("outsider cannot declare", "PERMISSION_DENIED",
    "Membership required.", () => declare(C, expenseId, B, 100));
  await rejects("amount above remaining debt", "FAILED_PRECONDITION",
    "Amount exceeds remaining debt.", () => declare(A, expenseId, B, 2501));
  await rejects("zero amount", "INVALID_ARGUMENT", "Invalid payment.",
    () => declare(A, expenseId, B, 0));
  await rejects("payment date in the future", "INVALID_ARGUMENT",
    "Invalid payment date.",
    () => declare(A, expenseId, B, 100, {paidOn: "2099-01-01"}));
  await rejects("methods must match the amount", "INVALID_ARGUMENT",
    "Payment total mismatch.", () => declare(A, expenseId, B, 100, {
      paymentMethods: [{payerUid: B, method: "cash", minorUnits: 50}],
    }));
}

async function concurrent() {
  const expenseId = await createExpense();
  const results = await Promise.allSettled([
    declare(A, expenseId, B, 3000),
    declare(A, expenseId, B, 3000),
  ]);
  const ok = results.filter((r) => r.status === "fulfilled");
  assert.equal(ok.length, 1, JSON.stringify(results.map((r) => r.status)));
  const total = (await refunds(expenseId).get()).docs
    .reduce((sum, d) => sum + d.data().minorUnits, 0);
  assert.equal(total, 3000);
  console.log("PASS: two concurrent declarations never exceed the debt");
}

async function voided() {
  const expenseId = await createExpense();
  const refundId = newId("pay");
  await call("declareBudgetPayment", A, {
    expenseId, refundId, debtorUid: B, minorUnits: 4000,
  });
  await rejects("debtor cannot void", "PERMISSION_DENIED", "Creditor only.",
    () => call("voidBudgetPayment", B,
      {expenseId, refundId, reason: "Not paid"}));
  await rejects("reason required", "INVALID_ARGUMENT", "Invalid reason.",
    () => call("voidBudgetPayment", A, {expenseId, refundId, reason: "x"}));
  await call("voidBudgetPayment", A, {
    expenseId, refundId, reason: "Importo sbagliato",
  });
  const record = (await refunds(expenseId).doc(refundId).get()).data();
  assert.equal(record.status, "voided");
  assert.equal(record.voidedByUid, A);
  assert.equal(record.voidReason, "Importo sbagliato");
  assert.ok(record.voidedAt);
  assert.equal(record.minorUnits, 4000, "nothing is deleted");
  await rejects("void twice", "FAILED_PRECONDITION", "Payment not active.",
    () => call("voidBudgetPayment", A,
      {expenseId, refundId, reason: "Again please"}));
  const full = await declare(A, expenseId, B, 5000);
  assert.equal(full.remainingMinor, 0);
  console.log("PASS: voided payment does not count (full debt declarable)");
  await rejects("debt fully paid", "FAILED_PRECONDITION",
    "Debt already settled.", () => declare(A, expenseId, B, 1));
  return expenseId;
}

async function pendingAndDeclared() {
  const expenseId = await createExpense();
  const requestId = newId("req");
  await call("requestBudgetReimbursement", B, {
    expenseId, refundId: requestId, creditorUid: A, minorUnits: 3000,
  });
  await declare(A, expenseId, B, 3000);
  const pending = (await refunds(expenseId).doc(requestId).get()).data();
  assert.equal(pending.status, "pending", "pending request stays as it is");
  await rejects("confirming the request now exceeds the debt",
    "FAILED_PRECONDITION", "Reimbursement exceeds remaining debt.",
    () => call("confirmBudgetReimbursement", A,
      {expenseId, refundId: requestId, approved: true}));
  await call("confirmBudgetReimbursement", A,
    {expenseId, refundId: requestId, approved: false});
  console.log("PASS: pending request plus declaration, clear error, reject ok");

  // A request that still fits can be confirmed after a declaration.
  const otherExpense = await createExpense();
  const smallRequest = newId("req");
  await call("requestBudgetReimbursement", B, {
    expenseId: otherExpense, refundId: smallRequest, creditorUid: A,
    minorUnits: 1000,
  });
  await declare(A, otherExpense, B, 4000);
  await call("confirmBudgetReimbursement", A,
    {expenseId: otherExpense, refundId: smallRequest, approved: true});
  console.log("PASS: request within the remaining debt still confirmable");
}

async function formerMember() {
  const expenseId = await createExpense(true);
  const declaredId = newId("pay");
  await call("declareBudgetPayment", A, {
    expenseId, refundId: declaredId, debtorUid: D, minorUnits: 1000,
  });
  // D leaves the trip.
  await db.collection("trips").doc(tripId).update({memberUids: [A, B]});
  await rejects("former member cannot get new declarations",
    "FAILED_PRECONDITION", "Debtor is not a trip member.",
    () => declare(A, expenseId, D, 500));
  const closed = await call("closeBudgetDebt", A, {
    expenseId, closureId: newId("close"), debtorUid: D,
    reason: "Left the trip",
  });
  assert.equal(closed.minorUnits, 4000, "closure covers the rest only");
  await rejects("a closed debt cannot be reopened by voiding",
    "FAILED_PRECONDITION", "Debt already closed.",
    () => call("voidBudgetPayment", A,
      {expenseId, refundId: declaredId, reason: "Wrong person"}));
  await db.collection("trips").doc(tripId).update({memberUids: [A, B, D]});
  console.log("PASS: former member debt and closure unchanged");
}

async function history(expenseId) {
  const one = await call("listBudgetHistory", B, {expenseId});
  const types = one.events.map((e) => e.type);
  assert.ok(types.includes("paymentDeclared"), types.join(","));
  assert.ok(types.includes("paymentVoided"), types.join(","));
  const declared = one.events.find((e) => e.type === "paymentDeclared");
  assert.equal(declared.actorUid, A);
  assert.equal(declared.counterpartUid, B);
  const voidedEvent = one.events.find((e) => e.type === "paymentVoided");
  assert.equal(voidedEvent.reason, "Importo sbagliato");
  const trip = await call("listBudgetHistory", B, {});
  assert.ok(trip.events.some((e) =>
    e.type === "paymentDeclared" && e.expenseId === expenseId));
  console.log("PASS: expense and trip history show declared and voided");
}

(async () => {
  await setup();
  await creditorRecords();
  await concurrent();
  const voidedExpense = await voided();
  await pendingAndDeclared();
  await formerMember();
  await history(voidedExpense);
  console.log("ALL DECLARED PAYMENT SCENARIOS PASSED");
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
