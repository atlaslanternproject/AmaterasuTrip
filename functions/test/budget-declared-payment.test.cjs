"use strict";

// Pagamenti dichiarati dal creditore: eventi dello storico e controlli
// su data, nota e motivo. Serve la build (npm run build).
// Uso: node --test functions/test/budget-declared-payment.test.cjs

const test = require("node:test");
const assert = require("node:assert/strict");
const {buildExpenseHistory} =
  require("../lib/budget/budget-history-events.js");
const {validatePaidOn, validateNote, validateReason} =
  require("../lib/budget/budget-payment-details.js");

const at = (ms) => ({toMillis: () => ms});
const empty = {
  revisions: [], reimbursements: [], cancellation: null,
  cancellationLog: [], fxRateChanges: [],
};
const expense = {snapshot: {total: {currency: "EUR", minorUnits: 1000}}};

test("declared payment appears as recorded by the creditor", () => {
  const events = buildExpenseHistory("e1", expense, {
    ...empty,
    reimbursements: [{
      kind: "declared", debtorUid: "b", creditorUid: "a", recordedByUid: "a",
      minorUnits: 400, status: "confirmed", createdAt: at(10),
    }],
  });
  assert.deepEqual(events.map((e) => e.type), ["paymentDeclared"]);
  assert.equal(events[0].actorUid, "a");
  assert.equal(events[0].counterpartUid, "b");
  assert.equal(events[0].minorUnits, 400);
  assert.equal(events[0].currency, "EUR");
});

test("voided declared payment shows both events with reason", () => {
  const events = buildExpenseHistory("e1", expense, {
    ...empty,
    reimbursements: [{
      kind: "declared", debtorUid: "b", creditorUid: "a", recordedByUid: "a",
      minorUnits: 400, status: "voided", createdAt: at(10),
      voidedByUid: "a", voidReason: "Wrong amount", voidedAt: at(20),
    }],
  });
  assert.deepEqual(events.map((e) => e.type),
    ["paymentVoided", "paymentDeclared"]);
  assert.equal(events[0].reason, "Wrong amount");
  assert.equal(events[0].actorUid, "a");
});

test("declared payments are never shown as debtor requests", () => {
  const events = buildExpenseHistory("e1", expense, {
    ...empty,
    reimbursements: [{
      kind: "declared", debtorUid: "b", creditorUid: "a", recordedByUid: "a",
      minorUnits: 400, status: "confirmed", createdAt: at(10),
    }],
  });
  assert.ok(!events.some((e) => e.type.startsWith("reimbursement")));
});

test("payment date: default today, real days only, not in the future", () => {
  const now = new Date("2026-11-21T10:00:00Z");
  assert.equal(validatePaidOn(undefined, now), "2026-11-21");
  assert.equal(validatePaidOn("2026-11-01", now), "2026-11-01");
  assert.equal(validatePaidOn("2026-11-22", now), "2026-11-22");
  for (const bad of ["2026-11-23", "2026-02-30", "21/11/2026", "1999-12-31",
    42, ""]) {
    assert.throws(() => validatePaidOn(bad, now), String(bad));
  }
});

test("note is optional and limited, reason needs 3 to 400 characters", () => {
  assert.equal(validateNote(undefined), null);
  assert.equal(validateNote("   "), null);
  assert.equal(validateNote(" contanti "), "contanti");
  assert.throws(() => validateNote("x".repeat(301)));
  assert.throws(() => validateNote(5));
  assert.equal(validateReason("  Importo sbagliato "), "Importo sbagliato");
  assert.throws(() => validateReason("ab"));
  assert.throws(() => validateReason("x".repeat(401)));
});
