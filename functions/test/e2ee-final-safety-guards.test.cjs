"use strict";

const {test} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "../..");

function source(relative) {
  return fs.readFileSync(path.join(root, relative), "utf8");
}

test("logout invalidates decrypted E2EE sessions", () => {
  const dart = source(
    "lib/features/settings/presentation/pages/account/account_logout.dart"
  );
  assert.match(
    dart,
    /VerifiedTripProfileSessions\.instance\.clear\(\);/
  );
});

test("every successful member removal invalidates local key leases", () => {
  const dart = source(
    "lib/features/trips/data/repositories/trip_member_repository.dart"
  );
  assert.match(
    dart,
    /VerifiedTripProfileSessions\.instance\.clearTrip\(tripId\);/
  );
  assert.doesNotMatch(
    dart,
    /if \(data\['leftTrip'\] == true\)/
  );
});

test("encrypted-trip removal is fail-closed pending rotation", () => {
  const ts = source("functions/src/index.ts");
  const block = ts.slice(ts.indexOf("export const removeTripMember"));
  assert.match(block, /containsProtectedProfiles/);
  assert.match(block, /"protectedDetails" in profile/);
  assert.match(block, /"failed-precondition"/);
  assert.ok(
    block.indexOf("containsProtectedProfiles") <
    block.indexOf("FieldValue.arrayRemove(targetUid)")
  );
});

test("the invitation and update endpoints still require encryption", () => {
  const ts = source("functions/src/index.ts");
  const matches = ts.match(/requireEncryptedTravellerProfile\(/g) || [];
  assert.equal(matches.length, 2);
});

test("local project version is unchanged", () => {
  const yaml = source("pubspec.yaml");
  assert.match(yaml, /^version: 1\.7\.1\+8\s*$/m);
});