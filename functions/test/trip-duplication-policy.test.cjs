"use strict";

// Quali sottoraccolte di un viaggio vengono copiate dalla duplicazione.
// Serve la build (npm run build).
// Uso: node --test functions/test/trip-duplication-policy.test.cjs

const test = require("node:test");
const assert = require("node:assert/strict");
const {shouldCopyTripSubcollection} =
  require("../lib/trip-management/trip-duplication-policy.js");

test("Hotel/Alloggi (stays) are never copied", () => {
  assert.equal(shouldCopyTripSubcollection("stays"), false);
});

test("trip sections (transports, bookings, ...) are never copied", () => {
  for (const id of [
    "transports", "reservations", "restaurants", "savedPlaces", "notes",
    "shoppingItems", "packingItems", "memories", "checklists",
  ]) {
    assert.equal(shouldCopyTripSubcollection(id), false, id);
  }
});

test("members and budget data are still not copied", () => {
  for (const id of ["members", "budgetSharedExpenses", "budgetPrivateOwners"]) {
    assert.equal(shouldCopyTripSubcollection(id), false, id);
  }
});

test("bucket list data is still copied", () => {
  for (const id of ["bucketList", "bucketCategories"]) {
    assert.equal(shouldCopyTripSubcollection(id), true, id);
  }
});
