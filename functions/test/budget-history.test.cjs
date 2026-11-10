"use strict";

// B8.6: pure history builder. Requires `npm run build` first.
// Run with: node --test functions/test/budget-history.test.cjs

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  buildExpenseHistory, sortHistory,
} = require("../lib/budget/budget-history-events.js");

const at = (ms) => ({toMillis: () => ms});
const empty = {
  revisions: [], reimbursements: [], cancellation: null,
  cancellationLog: [], fxRateChanges: [],
};
const expense = {
  snapshot: {total: {currency: "EUR", minorUnits: 1000}},
};

test("creation, revision and rate change", () => {
  const events = buildExpenseHistory("e1", expense, {
    ...empty,
    revisions: [
      {number: 1, actorUid: "a", createdAt: at(10)},
      {number: 2, actorUid: "b", createdAt: at(20)},
    ],
    fxRateChanges: [{actorUid: "a", reason: "Bank statement",
      next: {rate: 0.0061}, createdAt: at(30)}],
  });
  assert.deepEqual(events.map((e) => e.type),
    ["rateChanged", "revised", "created"]);
  assert.equal(events[0].rate, 0.0061);
  assert.equal(events[0].reason, "Bank statement");
  assert.equal(events[1].version, 2);
  assert.equal(events[2].actorUid, "a");
});

test("reimbursement requested, confirmed, rejected and closed", () => {
  const events = buildExpenseHistory("e1", expense, {
    ...empty,
    reimbursements: [
      {debtorUid: "b", creditorUid: "a", minorUnits: 300, status: "confirmed",
        decidedByUid: "a", createdAt: at(10), decidedAt: at(11)},
      {debtorUid: "b", creditorUid: "a", minorUnits: 100, status: "rejected",
        decidedByUid: "a", createdAt: at(12), decidedAt: at(13)},
      {debtorUid: "b", creditorUid: "a", minorUnits: 50, status: "pending",
        createdAt: at(14)},
      {kind: "closure", debtorUid: "c", creditorUid: "a", minorUnits: 200,
        status: "writtenOff", decidedByUid: "a", reason: "Left the trip",
        createdAt: at(15), decidedAt: at(15)},
    ],
  });
  assert.deepEqual(events.map((e) => e.type), [
    "debtClosed", "reimbursementRequested", "reimbursementRejected",
    "reimbursementRequested", "reimbursementConfirmed",
    "reimbursementRequested",
  ]);
  const closed = events[0];
  assert.equal(closed.actorUid, "a");
  assert.equal(closed.counterpartUid, "c");
  assert.equal(closed.minorUnits, 200);
  assert.equal(closed.currency, "EUR");
  assert.equal(closed.reason, "Left the trip");
  const confirmed = events[4];
  assert.equal(confirmed.actorUid, "a");
  assert.equal(confirmed.counterpartUid, "b");
});

test("cancellation log keeps every round", () => {
  const events = buildExpenseHistory("e1",
    {...expense, lifecycle: "cancelled", cancelledByUid: "b"}, {
      ...empty,
      cancellation: {state: "approved", requestedByUid: "a",
        createdAt: at(30)},
      cancellationLog: [
        {event: "requested", actorUid: "a", createdAt: at(10)},
        {event: "rejected", actorUid: "b", createdAt: at(11)},
        {event: "requested", actorUid: "a", createdAt: at(30)},
        {event: "approved", actorUid: "b", createdAt: at(31)},
        {event: "cancelled", actorUid: "b", createdAt: at(31)},
      ],
    });
  assert.deepEqual(events.map((e) => e.type), [
    "cancellationApproved", "cancelled", "cancellationRequested",
    "cancellationRejected", "cancellationRequested",
  ]);
});

test("old cancellation without log is still shown", () => {
  const rejected = buildExpenseHistory("e1", expense, {
    ...empty,
    cancellation: {state: "rejected", requestedByUid: "a",
      rejectedByUid: "b", createdAt: at(10), updatedAt: at(12)},
  });
  assert.deepEqual(rejected.map((e) => [e.type, e.actorUid]), [
    ["cancellationRejected", "b"], ["cancellationRequested", "a"],
  ]);
  const cancelled = buildExpenseHistory("e1", {
    ...expense, lifecycle: "cancelled", cancelledByUid: "a",
    cancelledAt: at(20),
  }, {...empty, cancellation: {state: "approved", requestedByUid: "a",
    createdAt: at(19)}});
  assert.deepEqual(cancelled.map((e) => e.type),
    ["cancelled", "cancellationRequested"]);
});

test("old expense with missing fields never breaks", () => {
  const events = buildExpenseHistory("old", {}, {
    ...empty,
    revisions: [{snapshot: {}}],
    reimbursements: [{status: "confirmed"}],
  });
  assert.equal(events.length, 3);
  for (const event of events) {
    assert.equal(event.expenseId, "old");
    assert.equal(event.at, null);
    assert.ok(!Object.values(event).includes(undefined));
  }
});

test("newest first, unknown times last, stable order", () => {
  const sorted = sortHistory([
    {type: "x", at: null}, {type: "a", at: 1}, {type: "b", at: 5},
    {type: "c", at: 1}, {type: "y", at: null},
  ]);
  assert.deepEqual(sorted.map((e) => e.type), ["b", "a", "c", "x", "y"]);
});
