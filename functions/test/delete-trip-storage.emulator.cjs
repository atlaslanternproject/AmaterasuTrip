// Test con emulatori (Firestore, Auth, Storage, Functions) di deleteTrip
// con le copertine in Storage. Due modalità:
//   normal       -> copertine del viaggio cancellate, il resto intatto,
//                   chi non è proprietario respinto
//   storage-down -> Storage irraggiungibile: errore e viaggio intatto
// Uso: vedi tool/check_all.sh (emu_delete_trip_storage).

"use strict";

const assert = require("node:assert/strict");
const {randomUUID} = require("node:crypto");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");

const MODE = process.argv[2] || "normal";
const PROJECT_ID = process.env.GCLOUD_PROJECT || "demo-amaterasu-delete-trip";

if (!PROJECT_ID.startsWith("demo-") ||
    process.env.FIRESTORE_EMULATOR_HOST !== "127.0.0.1:18080" ||
    process.env.FIREBASE_AUTH_EMULATOR_HOST !== "127.0.0.1:19099") {
  throw new Error("STOP: demo project and local emulators required.");
}
if (MODE === "normal" &&
    process.env.FIREBASE_STORAGE_EMULATOR_HOST !== "127.0.0.1:19199") {
  throw new Error("STOP: local Storage emulator required.");
}
if (MODE === "storage-down" &&
    process.env.FIREBASE_STORAGE_EMULATOR_HOST !== "127.0.0.1:1") {
  throw new Error("STOP: storage-down mode needs an unreachable Storage.");
}

const BUCKET = `${PROJECT_ID}.appspot.com`;
initializeApp({projectId: PROJECT_ID, storageBucket: BUCKET});
const db = getFirestore();

const authUrl = "http://127.0.0.1:19099/identitytoolkit.googleapis.com/v1/" +
  "accounts:signUp?key=fake-api-key";
const functionUrl =
  `http://127.0.0.1:15001/${PROJECT_ID}/europe-west1/deleteTrip`;

async function createUser(label) {
  const response = await fetch(authUrl, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      email: `${label}-${randomUUID()}@example.test`,
      password: "TestPassword123!",
      returnSecureToken: true,
    }),
  });
  const data = await response.json();
  assert.ok(response.ok, JSON.stringify(data));
  return {uid: data.localId, token: data.idToken};
}

async function createTrip(owner, members, coverPath) {
  const id = `trip-${randomUUID()}`;
  const ref = db.collection("trips").doc(id);
  await ref.set({
    ownerUid: owner.uid,
    memberUids: [owner.uid, ...members.map((m) => m.uid)],
    name: "Trip " + id,
    status: "active",
    coverPath,
  });
  await ref.collection("members").doc(owner.uid).set({uid: owner.uid});
  return {id, ref, name: "Trip " + id};
}

async function callDeleteTrip(user, trip) {
  const response = await fetch(functionUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${user.token}`,
    },
    body: JSON.stringify({
      data: {tripId: trip.id, confirmationName: trip.name},
    }),
  });
  return {status: response.status, body: await response.json()};
}

const bucket = () => getStorage().bucket(BUCKET);

async function upload(path) {
  await bucket().file(path).save(Buffer.from("img"), {contentType: "image/jpeg"});
}

async function exists(path) {
  const [found] = await bucket().file(path).exists();
  return found;
}

async function runNormal() {
  const owner = await createUser("owner");
  const member = await createUser("member");
  const stranger = await createUser("stranger");

  const trip = await createTrip(owner, [member],
    `users/${owner.uid}/trips/PLACEHOLDER/cover/c.jpg`);
  const ownerCover = `users/${owner.uid}/trips/${trip.id}/cover/cover_1.jpg`;
  const memberCover = `users/${member.uid}/trips/${trip.id}/cover/cover_2.jpg`;
  await trip.ref.update({coverPath: memberCover});

  const other = await createTrip(owner, [member], null);
  const otherCover = `users/${owner.uid}/trips/${other.id}/cover/cover_3.jpg`;
  const ownerPhoto = `users/${owner.uid}/profile/profile_1.jpg`;
  const memberPhoto = `users/${member.uid}/profile/profile_2.jpg`;

  for (const path of [ownerCover, memberCover, otherCover, ownerPhoto, memberPhoto]) {
    await upload(path);
  }

  // chi non è proprietario viene respinto e non cancella nulla
  for (const user of [member, stranger]) {
    const result = await callDeleteTrip(user, trip);
    assert.equal(result.status, 403, JSON.stringify(result.body));
    assert.equal(result.body.error.status, "PERMISSION_DENIED");
  }
  assert.ok((await trip.ref.get()).exists);
  assert.ok(await exists(ownerCover));
  assert.ok(await exists(memberCover));
  console.log("PASS (denied): non-owners cannot delete the trip or its files");

  // il proprietario elimina: spariscono entrambe le copertine
  const result = await callDeleteTrip(owner, trip);
  assert.equal(result.status, 200, JSON.stringify(result.body));
  assert.equal(result.body.result.deleted, true);
  assert.equal((await trip.ref.get()).exists, false);
  assert.equal(await exists(ownerCover), false);
  assert.equal(await exists(memberCover), false);
  console.log("PASS: owner deletes trip, own and member covers removed");

  // il resto resta intatto
  assert.ok((await other.ref.get()).exists);
  assert.ok(await exists(otherCover));
  assert.ok(await exists(ownerPhoto));
  assert.ok(await exists(memberPhoto));
  console.log("PASS: other trip covers and profile photos untouched");

  // un viaggio senza nessuna copertina si elimina lo stesso
  const empty = await createTrip(owner, [], null);
  const emptyResult = await callDeleteTrip(owner, empty);
  assert.equal(emptyResult.status, 200, JSON.stringify(emptyResult.body));
  console.log("PASS: trip without covers deleted (missing files are fine)");

  console.log("ALL DELETE TRIP STORAGE SCENARIOS PASSED");
}

async function runStorageDown() {
  const owner = await createUser("owner");
  const trip = await createTrip(owner, [], null);

  const result = await callDeleteTrip(owner, trip);
  assert.equal(result.status, 500, JSON.stringify(result.body));
  assert.equal(result.body.error.status, "INTERNAL");
  assert.ok((await trip.ref.get()).exists, "trip must still exist");
  assert.ok((await trip.ref.collection("members").doc(owner.uid).get()).exists);
  console.log("PASS: Storage error returns an error and leaves the trip intact");
  console.log("ALL DELETE TRIP STORAGE-DOWN SCENARIOS PASSED");
}

(MODE === "storage-down" ? runStorageDown() : runNormal()).catch((error) => {
  console.error(error);
  process.exit(1);
});
