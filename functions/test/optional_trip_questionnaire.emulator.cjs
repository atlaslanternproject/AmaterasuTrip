"use strict";

const assert = require("node:assert/strict");
const {randomUUID, createHash} = require("node:crypto");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getAuth} = require("firebase-admin/auth");

const PROJECT = "demo-amaterasu-security";

assert.equal(
  process.env.FIRESTORE_EMULATOR_HOST,
  "127.0.0.1:18080"
);

assert.equal(
  process.env.FIREBASE_AUTH_EMULATOR_HOST,
  "127.0.0.1:19099"
);

initializeApp({projectId: PROJECT});

const db = getFirestore();

const authUrl =
  "http://127.0.0.1:19099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key";

const functionUrl =
  "http://127.0.0.1:15001/demo-amaterasu-security/europe-west1/acceptTripInvite";

async function createUser(label) {
  const response = await fetch(authUrl, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      email: `${label}-${randomUUID()}@example.test`,
      password: "LocalTestPassword123!",
      returnSecureToken: true
    })
  });

  const data = await response.json();

  assert.ok(response.ok, JSON.stringify(data));
  assert.ok(data.localId);
  assert.ok(data.idToken);

  // In produzione Amaterasu richiede una email verificata.
  // Il test rispetta la stessa regola usando soltanto Auth Emulator.
  await getAuth().updateUser(data.localId, {
    emailVerified: true
  });

  const signInResponse = await fetch(
    "http://127.0.0.1:19099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-key",
    {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        email: data.email,
        password: "LocalTestPassword123!",
        returnSecureToken: true
      })
    }
  );

  const signedIn = await signInResponse.json();

  assert.ok(signInResponse.ok, JSON.stringify(signedIn));
  assert.ok(signedIn.idToken);

  const verifiedToken = await getAuth().verifyIdToken(
    signedIn.idToken
  );

  assert.equal(verifiedToken.email_verified, true);

  return {
    uid: data.localId,
    token: signedIn.idToken
  };
}

async function createFixture(label, owner) {
  const tripId = `optional-${label}-${randomUUID()}`;
  const token = randomUUID();

  const tokenHash = createHash("sha256")
    .update(token)
    .digest("hex");

  const tripRef = db.collection("trips").doc(tripId);

  await tripRef.set({
    ownerUid: owner.uid,
    memberUids: [owner.uid],
    name: "Questionnaire security test",
    status: "active"
  });

  await tripRef.collection("members").doc(owner.uid).set({
    uid: owner.uid,
    role: "admin",
    travellerProfileCompleted: true
  });

  await db.collection("tripInvites").doc(tripId).set({
    status: "active",
    tokenHash
  });

  return {
    tripId,
    token,
    tripRef
  };
}

async function acceptAs(
  user,
  fixture,
  profile,
  presenceConfirmed = true
) {
  const response = await fetch(functionUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${user.token}`
    },
    body: JSON.stringify({
      data: {
        tripId: fixture.tripId,
        token: fixture.token,
        presenceConfirmed,
        travellerProfile: profile
      }
    })
  });

  return {
    status: response.status,
    body: await response.json()
  };
}

async function assertJoined(
  result,
  fixture,
  owner,
  traveler
) {
  assert.equal(
    result.status,
    200,
    JSON.stringify(result.body)
  );

  assert.equal(result.body?.result?.accepted, true);
  assert.equal(result.body?.result?.role, "traveler");

  const trip = await fixture.tripRef.get();

  assert.deepEqual(
    [...trip.data().memberUids].sort(),
    [owner.uid, traveler.uid].sort()
  );

  const member = await fixture.tripRef
    .collection("members")
    .doc(traveler.uid)
    .get();

  assert.ok(member.exists);
  assert.equal(member.data().travellerProfileCompleted, true);

  return member.data().travellerProfile;
}

async function assertNotJoined(
  result,
  fixture,
  owner,
  traveler,
  errorCode
) {
  assert.equal(
    result.body?.error?.status,
    errorCode,
    JSON.stringify(result.body)
  );

  const trip = await fixture.tripRef.get();

  assert.deepEqual(trip.data().memberUids, [owner.uid]);

  const member = await fixture.tripRef
    .collection("members")
    .doc(traveler.uid)
    .get();

  assert.equal(member.exists, false);
}

async function main() {
  try {
    const owner = await createUser("owner");

    // TEST 1 - Nessuna risposta obbligatoria.
    {
      const traveler = await createUser("empty");
      const fixture = await createFixture("empty", owner);

      const result = await acceptAs(traveler, fixture, {});

      const profile = await assertJoined(
        result, fixture, owner, traveler
      );

      const fields = [
        "hasEsimOrInternet",
        "hasCheckedBaggage",
        "hasCabinBaggage10Kg",
        "hasAllergies",
        "hasIntolerances",
        "hasMedicalAccessibilityInfo"
      ];

      for (const field of fields) {
        assert.equal(profile[field], null);
      }

      console.log("PASS 1/5 - Partecipazione senza risposte");
    }

    // TEST 2 - SI senza descrizione sanitaria.
    {
      const traveler = await createUser("yes");
      const fixture = await createFixture("yes", owner);

      const result = await acceptAs(traveler, fixture, {
        hasAllergies: true,
        hasIntolerances: true,
        hasMedicalAccessibilityInfo: true
      });

      const profile = await assertJoined(
        result, fixture, owner, traveler
      );

      assert.equal(profile.hasAllergies, true);
      assert.equal(profile.hasIntolerances, true);
      assert.equal(profile.hasMedicalAccessibilityInfo, true);

      assert.equal(profile.allergies, "");
      assert.equal(profile.intolerances, "");
      assert.equal(profile.medicalAccessibilityInfo, "");

      console.log("PASS 2/5 - SI senza dettagli consentito");
    }

    // TEST 3 - Dettagli non dichiarati non memorizzati.
    {
      const traveler = await createUser("minimise");
      const fixture = await createFixture("minimise", owner);

      const result = await acceptAs(traveler, fixture, {
        hasAllergies: false,
        allergies: "DUMMY-NON-SALVARE",
        hasIntolerances: null,
        intolerances: "DUMMY-NON-SALVARE",
        hasMedicalAccessibilityInfo: false,
        medicalAccessibilityInfo: "DUMMY-NON-SALVARE"
      });

      const profile = await assertJoined(
        result, fixture, owner, traveler
      );

      assert.equal(profile.hasAllergies, false);
      assert.equal(profile.hasIntolerances, null);
      assert.equal(profile.hasMedicalAccessibilityInfo, false);

      assert.equal(profile.allergies, "");
      assert.equal(profile.intolerances, "");
      assert.equal(profile.medicalAccessibilityInfo, "");

      console.log("PASS 3/5 - Dettagli esclusi correttamente");
    }

    // TEST 4 - Tipo non valido rifiutato.
    {
      const traveler = await createUser("invalid");
      const fixture = await createFixture("invalid", owner);

      const result = await acceptAs(traveler, fixture, {
        hasAllergies: "yes"
      });

      await assertNotJoined(
        result,
        fixture,
        owner,
        traveler,
        "INVALID_ARGUMENT"
      );

      console.log("PASS 4/5 - Tipo non valido respinto");
    }

    // TEST 5 - Presenza non confermata.
    {
      const traveler = await createUser("unconfirmed");
      const fixture = await createFixture("unconfirmed", owner);

      const result = await acceptAs(
        traveler,
        fixture,
        {},
        false
      );

      await assertNotJoined(
        result,
        fixture,
        owner,
        traveler,
        "FAILED_PRECONDITION"
      );

      console.log("PASS 5/5 - Conferma partecipazione necessaria");
    }

    console.log("");
    console.log("BLOCCO 5.6C.4A: 5/5 TEST SUPERATI");
  } finally {
    await db.terminate();
  }
}

main().catch((error) => {
  console.error("BLOCCO 5.6C.4A: TEST FALLITO");
  console.error(error);
  process.exitCode = 1;
});