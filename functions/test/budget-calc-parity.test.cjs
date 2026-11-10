"use strict";

// Checks the Cloud Functions budget calculations against the same fixture
// used by the Flutter app (test/features/trips/budget/calculations/
// budget_debt_parity_test.dart). Requires `npm run build` first.
// Run with: node --test functions/test/budget-calc-parity.test.cjs

const test = require("node:test");
const assert = require("node:assert/strict");
const path = require("node:path");
const fs = require("node:fs");

const {
  debtAmount, sumReimbursements, settledStatuses,
} = require("../lib/budget/budget-validation.js");

const fixture = JSON.parse(fs.readFileSync(
  path.join(__dirname, "..", "..", "test", "fixtures",
    "budget_debt_parity.json"),
  "utf8",
));

for (const item of fixture.debtCases) {
  test(`debt allocation: ${item.name}`, () => {
    const snapshot = item.snapshot;
    const uids = [...new Set([
      ...Object.keys(snapshot.shares),
      ...Object.keys(snapshot.advances),
    ])];
    const actual = [];
    for (const debtor of uids) {
      for (const creditor of uids) {
        const minorUnits = debtAmount(snapshot, debtor, creditor);
        if (minorUnits > 0) {
          actual.push({debtorUid: debtor, creditorUid: creditor, minorUnits});
        }
      }
    }
    const key = (debt) => `${debt.debtorUid}>${debt.creditorUid}`;
    const sorted = (list) => [...list].sort((a, b) =>
      key(a) < key(b) ? -1 : key(a) > key(b) ? 1 : 0);
    assert.deepEqual(sorted(actual), sorted(item.debts));
  });
}

for (const item of fixture.settlementCases) {
  test(`settlement sums: ${item.name}`, () => {
    const {debtorUid, creditorUid, minorUnits} = item.debt;
    const settled = sumReimbursements(
      item.reimbursements, debtorUid, creditorUid, settledStatuses);
    const pending = sumReimbursements(
      item.reimbursements, debtorUid, creditorUid, ["pending"]);
    assert.equal(settled, item.settled);
    assert.equal(pending, item.pending);
    assert.equal(Math.max(0, minorUnits - settled), item.remaining);
  });
}
