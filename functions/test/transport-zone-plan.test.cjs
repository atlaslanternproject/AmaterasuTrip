"use strict";

// Piano della migrazione dei fusi dei trasporti: nomi IANA equivalenti,
// controllo dello stesso offset nella data, nessun campo esistente tolto.
// Uso: node --test functions/test/transport-zone-plan.test.cjs

const test = require("node:test");
const assert = require("node:assert/strict");
const {zoneForOffset, offsetOn, planTransport} =
  require("../scripts/transport-zone-plan.cjs");

test("whole hours and fixed half hours", () => {
  assert.equal(zoneForOffset("+01:00"), "Etc/GMT-1");
  assert.equal(zoneForOffset("-05:00"), "Etc/GMT+5");
  assert.equal(zoneForOffset("+00:00"), "Etc/UTC");
  assert.equal(zoneForOffset("+05:30"), "Asia/Kolkata");
  // St. John's (-03:30) has daylight saving: never guessed.
  assert.equal(zoneForOffset("-03:30"), null);
  assert.equal(offsetOn("Etc/GMT-9", "2027-04-12"), "+09:00");
  assert.equal(offsetOn("Asia/Kolkata", "2027-04-12"), "+05:30");
  assert.equal(offsetOn("Etc/UTC", "2027-04-12"), "+00:00");
});

test("a transport gets zones, offsets and times stay as they are", () => {
  const data = {
    departureDate: "2027-04-12", departureTime: "13:05",
    departureOffset: "+01:00", arrivalDate: "2027-04-13",
    arrivalTime: "09:40", arrivalOffset: "+09:00",
  };
  const before = JSON.stringify(data);
  const {set, skipped} = planTransport(data);
  assert.deepEqual(set, {departureZone: "Etc/GMT-1", arrivalZone: "Etc/GMT-9"});
  assert.deepEqual(skipped, []);
  assert.equal(JSON.stringify(data), before);
});

test("already migrated or unsafe offsets are not touched", () => {
  assert.deepEqual(planTransport({
    departureDate: "2027-04-12", departureOffset: "+01:00",
    extras: {departureZone: "Europe/Rome"},
  }).set, {});
  const plan = planTransport({
    departureDate: "2027-04-12", departureOffset: "-03:30",
  });
  assert.deepEqual(plan.set, {});
  assert.deepEqual(plan.skipped, ["departureOffset -03:30"]);
  assert.deepEqual(planTransport({departureDate: "2027-04-12"}).set, {});
});
