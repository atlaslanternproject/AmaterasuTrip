"use strict";

const assert = require("node:assert/strict");
const {randomUUID} = require("node:crypto");
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

const AUTH_BASE =
  "http://127.0.0.1:19099/identitytoolkit.googleapis.com/v1";

const FUNCTION_URL =
  "http://127.0.0.1:15001/demo-amaterasu-security/europe-west1/updateMyTripTravellerProfile";

async function createUser(label) {
  const email = `${label}-${randomUUID()}@example.test`;
  const password = "LocalTestPassword123!";

  const signup = await fetch(
    `${AUTH_BASE}/accounts:signUp?key=fake-key`,
    {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        email,
        password,
        returnSecureToken: true
      })
    }
  );

  const created = await signup.json();

  assert.ok(signup.ok, JSON.stringify(created));
  assert.ok(created.localId);

  await getAuth().updateUser(created.localId, {
    emailVerified: true
  });

  const signIn = await fetch(
    `${AUTH_BASE}/accounts:signInWithPassword?key=fake-key`,
    {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        email,
        password,
        returnSecureToken: true
      })
    }
  );

  const signedIn = await signIn.json();

  assert.ok(signIn.ok, JSON.stringify(signedIn));
  assert.ok(signedIn.idToken);

  const verified = await getAuth().verifyIdToken(
    signedIn.idToken
  );

  assert.equal(verified.email_verified, true);

  return {
    uid: created.localId,
    token: signedIn.idToken
  };
}

async function updateAs(user, tripId, profile, extra = {}) {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${user.token}`
    },
    body: JSON.stringify({
      data: {
        tripId,
        travellerProfile: profile,
        ...extra
      }
    })
  });

  return {
    status: response.status,
    body: await response.json()
  };
}

function assertSuccess(result, user, tripId) {
  assert.equal(
    result.status,
    200,
    JSON.stringify(result.body)
  );

  assert.equal(result.body?.result?.updated, true);
  assert.equal(result.body?.result?.uid, user.uid);
  assert.equal(result.body?.result?.tripId, tripId);
}

function assertError(result, expectedStatus) {
  assert.equal(
    result.body?.error?.status,
    expectedStatus,
    JSON.stringify(result.body)
  );
}

async function getMember(tripRef, uid) {
  const snapshot = await tripRef
    .collection("members")
    .doc(uid)
    .get();

  return snapshot;
}

async function main() {
  try {
    const owner = await createUser("owner");
    const alice = await createUser("alice");
    const bob = await createUser("bob");
    const outsider = await createUser("outsider");

    const tripId = `profile-test-${randomUUID()}`;
    const tripRef = db.collection("trips").doc(tripId);

    const originalMembers = [
      owner.uid,
      alice.uid,
      bob.uid
    ];

    await tripRef.set({
      ownerUid: owner.uid,
      memberUids: originalMembers,
      name: "Profile privacy emulator test",
      status: "active"
    });

    await tripRef.collection("members").doc(owner.uid).set({
      uid: owner.uid,
      role: "admin",
      travellerProfileCompleted: true
    });

    // Solo dati sintetici creati sull'emulatore.
    await tripRef.collection("members").doc(alice.uid).set({
      uid: alice.uid,
      role: "traveler",
      travellerProfileCompleted: true,
      travellerProfile: {
        hasEsimOrInternet: true,
        hasCheckedBaggage: true,
        hasCabinBaggage10Kg: false,
        hasAllergies: true,
        hasIntolerances: true,
        hasMedicalAccessibilityInfo: true,
        allergies: "DUMMY-ALLERGIES",
        intolerances: "DUMMY-INTOLERANCES",
        medicalAccessibilityInfo: "DUMMY-MEDICAL",
        emergencyContactName: "DUMMY-CONTACT",
        emergencyContactPhone: "DUMMY-PHONE"
      }
    });

    await tripRef.collection("members").doc(bob.uid).set({
      uid: bob.uid,
      role: "traveler",
      travellerProfileCompleted: true,
      travellerProfile: {
        hasAllergies: null,
        hasIntolerances: null,
        hasMedicalAccessibilityInfo: null,
        allergies: "",
        intolerances: "",
        medicalAccessibilityInfo: "",
        emergencyContactName: "",
        emergencyContactPhone: ""
      }
    });

    // TEST 1 - Ritiro completo delle dichiarazioni.
    {
      const result = await updateAs(alice, tripId, {});

      assertSuccess(result, alice, tripId);

      const member = await getMember(tripRef, alice.uid);
      const profile = member.data().travellerProfile;

      for (const field of [
        "hasEsimOrInternet",
        "hasCheckedBaggage",
        "hasCabinBaggage10Kg",
        "hasAllergies",
        "hasIntolerances",
        "hasMedicalAccessibilityInfo"
      ]) {
        assert.equal(profile[field], null);
      }

      for (const field of [
        "allergies",
        "intolerances",
        "medicalAccessibilityInfo",
        "emergencyContactName",
        "emergencyContactPhone"
      ]) {
        assert.equal(profile[field], "");
      }

      assert.equal(member.data().role, "traveler");

      console.log(
        "PASS 1/5 - Dichiarazioni ritirate e dettagli svuotati"
      );
    }

    // TEST 2 - SI senza descrizione e minimizzazione.
    {
      const result = await updateAs(bob, tripId, {
        hasAllergies: true,
        hasIntolerances: false,
        intolerances: "DUMMY-DA-ESCLUDERE",
        hasMedicalAccessibilityInfo: null,
        medicalAccessibilityInfo: "DUMMY-DA-ESCLUDERE"
      });

      assertSuccess(result, bob, tripId);

      const member = await getMember(tripRef, bob.uid);
      const profile = member.data().travellerProfile;

      assert.equal(profile.hasAllergies, true);
      assert.equal(profile.allergies, "");

      assert.equal(profile.hasIntolerances, false);
      assert.equal(profile.intolerances, "");

      assert.equal(profile.hasMedicalAccessibilityInfo, null);
      assert.equal(profile.medicalAccessibilityInfo, "");

      console.log(
        "PASS 2/5 - SI senza dettagli e campi non pertinenti esclusi"
      );
    }

    // TEST 3 - Tipo non valido, nessuna scrittura.
    {
      const before = await getMember(tripRef, bob.uid);

      const result = await updateAs(bob, tripId, {
        hasAllergies: "yes"
      });

      assertError(result, "INVALID_ARGUMENT");

      const after = await getMember(tripRef, bob.uid);

      assert.deepEqual(
        after.data().travellerProfile,
        before.data().travellerProfile
      );

      assert.equal(
        after.updateTime.toMillis(),
        before.updateTime.toMillis()
      );

      console.log(
        "PASS 3/5 - Valore non valido respinto senza modifiche"
      );
    }

    // TEST 4 - Utente esterno senza autorizzazione.
    {
      const result = await updateAs(outsider, tripId, {
        hasAllergies: false
      });

      assertError(result, "PERMISSION_DENIED");

      const outsiderMember = await getMember(
        tripRef,
        outsider.uid
      );

      assert.equal(outsiderMember.exists, false);

      const trip = await tripRef.get();

      assert.deepEqual(
        trip.data().memberUids,
        originalMembers
      );

      console.log(
        "PASS 4/5 - Utente esterno respinto"
      );
    }

    // TEST 5 - Impossibile alterare il profilo altrui.
    {
      const bobBefore = await getMember(tripRef, bob.uid);

      const result = await updateAs(
        alice,
        tripId,
        {
          hasAllergies: false,
          allergies: "DUMMY-DA-ESCLUDERE"
        },
        {
          targetUid: bob.uid
        }
      );

      assertSuccess(result, alice, tripId);

      const aliceAfter = await getMember(tripRef, alice.uid);
      const bobAfter = await getMember(tripRef, bob.uid);

      assert.equal(
        aliceAfter.data().travellerProfile.hasAllergies,
        false
      );

      assert.equal(
        aliceAfter.data().travellerProfile.allergies,
        ""
      );

      assert.deepEqual(
        bobAfter.data(),
        bobBefore.data()
      );

      console.log(
        "PASS 5/5 - Modificabile soltanto il proprio profilo"
      );
    }

    console.log("");
    console.log("BLOCCO 5.6C.4B: 5/5 TEST SUPERATI");
  } finally {
    await db.terminate();
  }
}

main().catch((error) => {
  console.error("BLOCCO 5.6C.4B: TEST FALLITO");
  console.error(error);
  process.exitCode = 1;
});