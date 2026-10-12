"use strict";

const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

const PROJECT_ID = "demo-amaterasu-security";

assert.equal(
  process.env.FIRESTORE_EMULATOR_HOST,
  "127.0.0.1:18080",
  "STOP: Firestore locale non verificato"
);

assert.equal(
  process.env.FIREBASE_AUTH_EMULATOR_HOST,
  "127.0.0.1:19099",
  "STOP: Auth locale non verificato"
);

initializeApp({ projectId: PROJECT_ID });

const db = getFirestore();

const authUrl =
  "http://127.0.0.1:19099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key";

const functionUrl =
  "http://127.0.0.1:15001/demo-amaterasu-security/europe-west1/removeTripMember";

async function createUser(label) {
  const response = await fetch(authUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email: `${label}-${randomUUID()}@example.test`,
      password: "TestPassword123!",
      returnSecureToken: true
    })
  });

  const data = await response.json();

  assert.ok(
    response.ok,
    `Creazione utente fittizio fallita: ${JSON.stringify(data)}`
  );

  assert.ok(data.localId && data.idToken);

  return {
    uid: data.localId,
    token: data.idToken
  };
}

async function createTrip(label, owner, first, second) {
  const id = `security-${label}-${randomUUID()}`;
  const tripRef = db.collection("trips").doc(id);

  const users = [owner, first, second];

  await tripRef.set({
    ownerUid: owner.uid,
    memberUids: users.map(user => user.uid),
    name: "Security test trip",
    status: "active"
  });

  for (const user of users) {
    await tripRef.collection("members").doc(user.uid).set({
      uid: user.uid,
      role: user.uid === owner.uid ? "admin" : "traveler",
      travellerProfileCompleted: false
    });
  }

  return tripRef;
}

async function removeAs(user, tripId, targetUid) {
  const response = await fetch(functionUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${user.token}`
    },
    body: JSON.stringify({
      data: {
        tripId,
        targetUid
      }
    })
  });

  return {
    status: response.status,
    body: await response.json()
  };
}

async function checkState(tripRef, expectedUsers, removedUsers = []) {
  const trip = await tripRef.get();

  assert.ok(trip.exists);

  const actualUids = trip.data().memberUids.slice().sort();
  const expectedUids = expectedUsers.map(user => user.uid).sort();

  assert.deepEqual(actualUids, expectedUids);

  for (const user of expectedUsers) {
    const member = await tripRef
      .collection("members")
      .doc(user.uid)
      .get();

    assert.ok(member.exists, "Documento membro mancante");
  }

  for (const user of removedUsers) {
    const member = await tripRef
      .collection("members")
      .doc(user.uid)
      .get();

    assert.equal(member.exists, false);
  }
}

function expectError(result, code) {
  assert.equal(
    result.body?.error?.status,
    code,
    `Atteso ${code}; ottenuto ${JSON.stringify(result.body)}`
  );
}

function expectSuccess(result) {
  assert.equal(
    result.status,
    200,
    `HTTP inatteso: ${JSON.stringify(result.body)}`
  );

  assert.equal(result.body?.result?.removed, true);
}

async function main() {
  try {
    const owner = await createUser("owner");
    const first = await createUser("traveler-a");
    const second = await createUser("traveler-b");
    const outsider = await createUser("outsider");

    const members = [owner, first, second];

    // 1. An outsider cannot remove a member.
    {
      const trip = await createTrip("outsider", ...members);

      const result = await removeAs(
        outsider,
        trip.id,
        second.uid
      );

      expectError(result, "PERMISSION_DENIED");
      await checkState(trip, members);

      console.log("PASS 1/5 - Estraneo respinto");
    }

    // 2. One traveler cannot expel another.
    {
      const trip = await createTrip("unauthorized", ...members);

      const result = await removeAs(
        first,
        trip.id,
        second.uid
      );

      expectError(result, "PERMISSION_DENIED");
      await checkState(trip, members);

      console.log("PASS 2/5 - Espulsione non autorizzata respinta");
    }

    // 3. A traveler may voluntarily leave.
    {
      const trip = await createTrip("leave", ...members);

      const result = await removeAs(
        first,
        trip.id,
        first.uid
      );

      expectSuccess(result);
      await checkState(trip, [owner, second], [first]);

      console.log("PASS 3/5 - Uscita volontaria consentita");
    }

    // 4. The owner may remove a traveler.
    {
      const trip = await createTrip("owner", ...members);

      const result = await removeAs(
        owner,
        trip.id,
        second.uid
      );

      expectSuccess(result);
      await checkState(trip, [owner, first], [second]);

      console.log("PASS 4/5 - Espulsione del proprietario consentita");
    }

    // 5. The owner cannot be removed.
    {
      const trip = await createTrip("protected-owner", ...members);

      const result = await removeAs(
        owner,
        trip.id,
        owner.uid
      );

      expectError(result, "FAILED_PRECONDITION");
      await checkState(trip, members);

      console.log("PASS 5/5 - Proprietario protetto");
    }

    console.log("");
    console.log("BLOCCO 5.5C: 5/5 TEST SUPERATI");
  } finally {
    await db.terminate();
  }
}

main().catch(error => {
  console.error("BLOCCO 5.5C: TEST FALLITO");
  console.error(error.message);
  process.exitCode = 1;
});