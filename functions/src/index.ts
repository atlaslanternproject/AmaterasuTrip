import {createHash, randomBytes} from "crypto";

import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {setGlobalOptions} from "firebase-functions";
import {HttpsError, onCall} from "firebase-functions/v2/https";

initializeApp();

setGlobalOptions({
  maxInstances: 10,
  region: "europe-west1",
});

const db = getFirestore();

/**
 * Creates the SHA-256 hash stored for an invitation token.
 *
 * @param {string} token Raw invitation token.
 * @return {string} SHA-256 hexadecimal hash.
 */
function hashInviteToken(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}

export const createTripInvite = onCall(async (request) => {
  const uid = request.auth?.uid;

  if (uid == null) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication is required.",
    );
  }

  const tripId = request.data?.tripId;

  if (typeof tripId !== "string" || tripId.trim().length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "A valid tripId is required.",
    );
  }

  const tripRef = db.collection("trips").doc(tripId);
  const tripSnapshot = await tripRef.get();

  if (!tripSnapshot.exists) {
    throw new HttpsError(
      "not-found",
      "Trip not found.",
    );
  }

  const tripData = tripSnapshot.data();

  if (tripData?.ownerUid !== uid) {
    throw new HttpsError(
      "permission-denied",
      "Only the trip owner can create invitations.",
    );
  }

  const token = randomBytes(32).toString("base64url");
  const tokenHash = hashInviteToken(token);

  const inviteRef = db.collection("tripInvites").doc(tripId);

  await db.runTransaction(async (transaction) => {
    const inviteSnapshot = await transaction.get(inviteRef);
    const currentVersion = inviteSnapshot.exists ?
      inviteSnapshot.data()?.version ?? 0 :
      0;

    transaction.set(inviteRef, {
      tripId,
      tokenHash,
      createdByUid: uid,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      status: "active",
      version: currentVersion + 1,
    });
  });

  return {
    inviteId: tripId,
    token,
  };
});
export const revokeTripInvite = onCall(async (request) => {
  const uid = request.auth?.uid;

  if (uid == null) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication is required.",
    );
  }

  const tripId = request.data?.tripId;

  if (typeof tripId !== "string" || tripId.trim().length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "A valid tripId is required.",
    );
  }

  const tripRef = db.collection("trips").doc(tripId);
  const inviteRef = db.collection("tripInvites").doc(tripId);

  const tripSnapshot = await tripRef.get();

  if (!tripSnapshot.exists) {
    throw new HttpsError(
      "not-found",
      "Trip not found.",
    );
  }

  if (tripSnapshot.data()?.ownerUid !== uid) {
    throw new HttpsError(
      "permission-denied",
      "Only the trip owner can revoke invitations.",
    );
  }

  const inviteSnapshot = await inviteRef.get();

  if (!inviteSnapshot.exists) {
    return {
      revoked: false,
    };
  }

  await inviteRef.update({
    status: "revoked",
    revokedByUid: uid,
    revokedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return {
    revoked: true,
  };
});

export const validateTripInvite = onCall(async (request) => {
  const tripId = request.data?.tripId;
  const token = request.data?.token;

  if (
    typeof tripId !== "string" ||
    tripId.trim().length === 0 ||
    typeof token !== "string" ||
    token.length === 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      "A valid tripId and token are required.",
    );
  }

  const inviteRef = db.collection("tripInvites").doc(tripId);
  const inviteSnapshot = await inviteRef.get();

  if (!inviteSnapshot.exists) {
    throw new HttpsError(
      "not-found",
      "Invitation not found.",
    );
  }

  const inviteData = inviteSnapshot.data();

  if (
    inviteData?.status !== "active" ||
    inviteData?.tokenHash !== hashInviteToken(token)
  ) {
    throw new HttpsError(
      "permission-denied",
      "Invitation is invalid or no longer active.",
    );
  }

  const tripSnapshot = await db.collection("trips").doc(tripId).get();

  if (!tripSnapshot.exists) {
    throw new HttpsError(
      "not-found",
      "Trip not found.",
    );
  }

  const tripData = tripSnapshot.data();

  return {
    valid: true,
    trip: {
      id: tripSnapshot.id,
      name: tripData?.name ?? "",
      destination: tripData?.destination ?? "",
      startDate: tripData?.startDate?.toMillis?.() ?? null,
      endDate: tripData?.endDate?.toMillis?.() ?? null,
    },
  };
});
export const migrateOwnedTripsMembership = onCall(async (request) => {
  const uid = request.auth?.uid;

  if (uid == null) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication is required.",
    );
  }

  const tripsSnapshot = await db
    .collection("trips")
    .where("ownerUid", "==", uid)
    .get();

  let migratedTrips = 0;

  for (const tripSnapshot of tripsSnapshot.docs) {
    const tripRef = tripSnapshot.ref;
    const ownerMemberRef = tripRef.collection("members").doc(uid);
    const batch = db.batch();

    batch.update(tripRef, {
      memberUids: FieldValue.arrayUnion(uid),
    });

    batch.set(
      ownerMemberRef,
      {
        uid,
        role: "admin",
        joinedAt: FieldValue.serverTimestamp(),
        travellerProfileCompleted: true,
      },
      {merge: true},
    );

    await batch.commit();
    migratedTrips++;
  }

  return {
    migratedTrips,
  };
});
export const acceptTripInvite = onCall(async (request) => {
  const uid = request.auth?.uid;

  if (uid == null) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication is required.",
    );
  }

  const tripId = request.data?.tripId;
  const token = request.data?.token;
  const presenceConfirmed = request.data?.presenceConfirmed;
  const travellerProfile = request.data?.travellerProfile;

  if (
    typeof tripId !== "string" ||
    tripId.trim().length === 0 ||
    typeof token !== "string" ||
    token.length === 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      "A valid tripId and token are required.",
    );
  }

  if (presenceConfirmed !== true) {
    throw new HttpsError(
      "failed-precondition",
      "Final participation confirmation is required.",
    );
  }

  if (
    travellerProfile == null ||
    typeof travellerProfile !== "object" ||
    Array.isArray(travellerProfile)
  ) {
    throw new HttpsError(
      "invalid-argument",
      "A completed traveller profile is required.",
    );
  }

  const hasEsimOrInternet = travellerProfile.hasEsimOrInternet;
  const hasCheckedBaggage = travellerProfile.hasCheckedBaggage;
  const hasCabinBaggage10Kg = travellerProfile.hasCabinBaggage10Kg;

  if (
    typeof hasEsimOrInternet !== "boolean" ||
    typeof hasCheckedBaggage !== "boolean" ||
    typeof hasCabinBaggage10Kg !== "boolean"
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Traveller questionnaire is incomplete.",
    );
  }

  const optionalTextFields = [
    "allergies",
    "intolerances",
    "medicalAccessibilityInfo",
    "emergencyContactName",
    "emergencyContactPhone",
  ];

  for (const field of optionalTextFields) {
    const value = travellerProfile[field];

    if (value != null && typeof value !== "string") {
      throw new HttpsError(
        "invalid-argument",
        `Invalid traveller profile field: ${field}.`,
      );
    }
  }

  const inviteRef = db.collection("tripInvites").doc(tripId);
  const tripRef = db.collection("trips").doc(tripId);
  const memberRef = tripRef.collection("members").doc(uid);

  await db.runTransaction(async (transaction) => {
    const [inviteSnapshot, tripSnapshot, memberSnapshot] = await Promise.all([
      transaction.get(inviteRef),
      transaction.get(tripRef),
      transaction.get(memberRef),
    ]);

    if (!inviteSnapshot.exists) {
      throw new HttpsError(
        "not-found",
        "Invitation not found.",
      );
    }

    const inviteData = inviteSnapshot.data();

    if (
      inviteData?.status !== "active" ||
      inviteData?.tokenHash !== hashInviteToken(token)
    ) {
      throw new HttpsError(
        "permission-denied",
        "Invitation is invalid or no longer active.",
      );
    }

    if (!tripSnapshot.exists) {
      throw new HttpsError(
        "not-found",
        "Trip not found.",
      );
    }

    const tripData = tripSnapshot.data();

    if (tripData?.ownerUid === uid) {
      throw new HttpsError(
        "failed-precondition",
        "The trip owner is already an administrator.",
      );
    }

    if (memberSnapshot.exists) {
      throw new HttpsError(
        "already-exists",
        "The user is already a member of this trip.",
      );
    }

    transaction.update(tripRef, {
      memberUids: FieldValue.arrayUnion(uid),
      updatedAt: FieldValue.serverTimestamp(),
    });

    transaction.set(memberRef, {
      uid,
      role: "traveler",
      joinedAt: FieldValue.serverTimestamp(),
      travellerProfileCompleted: true,
      travellerProfile: {
        hasEsimOrInternet,
        hasCheckedBaggage,
        hasCabinBaggage10Kg,
        allergies: travellerProfile.allergies?.trim() ?? "",
        intolerances: travellerProfile.intolerances?.trim() ?? "",
        medicalAccessibilityInfo:
          travellerProfile.medicalAccessibilityInfo?.trim() ?? "",
        emergencyContactName:
          travellerProfile.emergencyContactName?.trim() ?? "",
        emergencyContactPhone:
          travellerProfile.emergencyContactPhone?.trim() ?? "",
      },
    });
  });

  return {
    accepted: true,
    tripId,
    role: "traveler",
  };
});
