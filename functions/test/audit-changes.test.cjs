"use strict";

// Audit Trail (v1.58.0): cosa entra nel registro. Sezioni registrate,
// documenti privati esclusi, campi tecnici ignorati, campi sensibili solo
// "cambiato", testi e mappe tagliati, azioni, nome dell'elemento e
// registro escluso dalla copia del viaggio. Serve la build.
// Uso: node --test functions/test/audit-changes.test.cjs

const test = require("node:test");
const assert = require("node:assert/strict");
const {Timestamp} = require("firebase-admin/firestore");
const a = require("../lib/audit/audit-changes.js");
const {shouldCopyTripSubcollection} =
  require("../lib/trip-management/trip-duplication-policy.js");

test("only the new sections are recorded, never budget or stays", () => {
  for (const s of ["transports", "notes", "checklists", "memories",
    "itinerary"]) {
    assert.ok(a.auditSections.has(s), s);
  }
  for (const s of ["stays", "bucketList", "budgetSharedExpenses",
    "auditTrail", "weatherCache", "members"]) {
    assert.ok(!a.auditSections.has(s), s);
  }
});

test("private notes and checklists are never recorded", () => {
  assert.equal(a.isPrivate({visibility: "private"}), true);
  assert.equal(a.isPrivate({visibility: "shared"}), false);
  assert.equal(a.isPrivate(undefined), false);
});

test("changes: before and after, technical fields ignored", () => {
  const before = {name: "Volo", number: "AZ1", updatedByUid: "a",
    updatedAt: Timestamp.fromMillis(1), createdByUid: "a"};
  const after = {name: "Volo", number: "AZ2", seats: "12A",
    updatedByUid: "b", updatedAt: Timestamp.fromMillis(2),
    createdByUid: "a"};
  assert.deepEqual(a.auditChanges(before, after), {
    number: {before: "AZ1", after: "AZ2"},
    seats: {before: null, after: "12A"},
  });
  assert.deepEqual(a.auditChanges(before, {...before, updatedByUid: "c"}), {});
});

test("sensitive, long and structured values", () => {
  const c = a.auditChanges(
    {doorCode: "1234", body: "x".repeat(300)},
    {doorCode: "9999", body: "y", checklist: [{text: "Passaporto"}]},
  );
  assert.deepEqual(c.doorCode, {before: "•", after: "•"});
  assert.equal(c.body.before.length, a.maxText + 1);
  assert.equal(c.checklist.after, '[{"text":"Passaporto"}]');
  assert.equal(a.auditValue(Timestamp.fromMillis(0)),
    "1970-01-01T00:00:00.000Z");
});

test("action and item name", () => {
  assert.equal(a.auditAction(false, true), "create");
  assert.equal(a.auditAction(true, true), "update");
  assert.equal(a.auditAction(true, false), "delete");
  assert.equal(a.auditItemName({title: "Frasi utili"}), "Frasi utili");
  assert.equal(a.auditItemName({}), "");
  assert.equal(a.auditItemName({name: "n".repeat(100)}).length, 81);
});

test("the register is never copied by trip duplication", () => {
  assert.equal(shouldCopyTripSubcollection("auditTrail"), false);
  assert.equal(shouldCopyTripSubcollection("itinerary"), false);
});
