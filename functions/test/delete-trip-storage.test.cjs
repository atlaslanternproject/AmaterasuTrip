// Test del calcolo dei file di Storage da cancellare con un viaggio
// (functions/src/trip-management/delete-trip-storage.ts). Serve la build.
// Uso: node --test functions/test/delete-trip-storage.test.cjs

"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  planTripStorageDeletion,
  deleteTripStorage,
  TripStoragePlanError,
} = require("../lib/trip-management/delete-trip-storage.js");

const plan = (overrides = {}) => planTripStorageDeletion({
  tripId: "trip1",
  ownerUid: "anna",
  memberUids: ["anna", "bruno"],
  coverPath: "users/anna/trips/trip1/cover/cover_1.jpg",
  ...overrides,
});

test("owner and members each get their cover folder, once", () => {
  assert.deepEqual(plan().prefixes, [
    "users/anna/trips/trip1/cover/",
    "users/bruno/trips/trip1/cover/",
  ]);
});

test("owner is included even when missing from memberUids", () => {
  assert.deepEqual(plan({memberUids: ["bruno"]}).prefixes, [
    "users/anna/trips/trip1/cover/",
    "users/bruno/trips/trip1/cover/",
  ]);
  assert.deepEqual(plan({memberUids: undefined}).prefixes, [
    "users/anna/trips/trip1/cover/",
  ]);
});

test("current cover inside the folders is not listed twice", () => {
  assert.deepEqual(plan().extraPaths, []);
  assert.deepEqual(
    plan({coverPath: "users/bruno/trips/trip1/cover/c.png"}).extraPaths,
    [],
  );
});

test("cover of a former member is added as a single file", () => {
  assert.deepEqual(
    plan({coverPath: "users/carla/trips/trip1/cover/cover_9.jpg"}).extraPaths,
    ["users/carla/trips/trip1/cover/cover_9.jpg"],
  );
});

test("a coverPath that is not a cover of this trip is never trusted", () => {
  for (const coverPath of [
    "users/carla/profile/profile_1.jpg",
    "users/carla/trips/other/cover/c.jpg",
    "users/carla/trips/trip1/cover/a/b.jpg",
    "users/carla/trips/trip1/cover/",
    "users/../trips/trip1/cover/c.jpg",
    "other/carla/trips/trip1/cover/c.jpg",
    "",
    42,
    null,
  ]) {
    assert.deepEqual(plan({coverPath}).extraPaths, [], String(coverPath));
  }
});

test("invalid tripId is rejected", () => {
  for (const tripId of ["", "a/b", " trip1", "..", undefined, 7]) {
    assert.throws(() => plan({tripId}), TripStoragePlanError, String(tripId));
  }
});

test("invalid owner or member UID is rejected", () => {
  assert.throws(() => plan({ownerUid: "an/na"}), TripStoragePlanError);
  assert.throws(() => plan({ownerUid: ""}), TripStoragePlanError);
  assert.throws(() => plan({memberUids: ["anna", "x/y"]}), TripStoragePlanError);
  assert.throws(() => plan({memberUids: ["anna", 3]}), TripStoragePlanError);
});

function fakeBucket({failPrefix, failFile} = {}) {
  const calls = [];
  return {
    calls,
    async deleteFiles({prefix}) {
      calls.push(["prefix", prefix]);
      if (prefix === failPrefix) throw new Error("storage down");
    },
    file(path) {
      return {
        async delete(options) {
          calls.push(["file", path, options.ignoreNotFound]);
          if (path === failFile) throw new Error("storage down");
        },
      };
    },
  };
}

test("every prefix and extra file is deleted, missing files ignored", async () => {
  const bucket = fakeBucket();
  const p = plan({coverPath: "users/carla/trips/trip1/cover/c.jpg"});
  await deleteTripStorage(bucket, p);
  assert.deepEqual(bucket.calls, [
    ["prefix", "users/anna/trips/trip1/cover/"],
    ["prefix", "users/bruno/trips/trip1/cover/"],
    ["file", "users/carla/trips/trip1/cover/c.jpg", true],
  ]);
});

test("a Storage error is passed to the caller", async () => {
  await assert.rejects(
    deleteTripStorage(
      fakeBucket({failPrefix: "users/bruno/trips/trip1/cover/"}),
      plan(),
    ),
    /storage down/,
  );
  await assert.rejects(
    deleteTripStorage(
      fakeBucket({failFile: "users/carla/trips/trip1/cover/c.jpg"}),
      plan({coverPath: "users/carla/trips/trip1/cover/c.jpg"}),
    ),
    /storage down/,
  );
});
