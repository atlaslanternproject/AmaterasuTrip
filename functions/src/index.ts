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

/**
 * Checks whether a trip member can manage invitation links.
 *
 * Client permissions are exposed through TripAccessPolicy.
 * Cloud Functions enforce the same current membership rule
 * because client-side checks are not a security boundary.
 *
 * @param {Object|undefined} tripData Trip document data.
 * @param {string} uid Authenticated user UID.
 * @return {boolean} Whether the member can manage invitations.
 */
function canManageTripInvitations(
  tripData: {
    ownerUid?: unknown;
    memberUids?: unknown;
  } | undefined,
  uid: string,
): boolean {
  if (tripData?.ownerUid === uid) {
    return true;
  }

  const memberUids = tripData?.memberUids;

  return Array.isArray(memberUids) &&
    memberUids.includes(uid);
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

  if (!canManageTripInvitations(tripData, uid)) {
    throw new HttpsError(
      "permission-denied",
      "Only trip members can manage invitations.",
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

  const tripData = tripSnapshot.data();

  if (!canManageTripInvitations(tripData, uid)) {
    throw new HttpsError(
      "permission-denied",
      "Only trip members can manage invitations.",
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

export const getTripInviteStatus = onCall(async (request) => {
  const uid = request.auth?.uid;

  if (uid == null) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication is required.",
    );
  }

  const tripId = request.data?.tripId;

  if (
    typeof tripId !== "string" ||
    tripId.trim().length === 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      "A valid tripId is required.",
    );
  }

  const tripRef =
      db.collection("trips").doc(tripId);

  const inviteRef =
      db.collection("tripInvites").doc(tripId);

  const [tripSnapshot, inviteSnapshot] =
      await Promise.all([
        tripRef.get(),
        inviteRef.get(),
      ]);

  if (!tripSnapshot.exists) {
    throw new HttpsError(
      "not-found",
      "Trip not found.",
    );
  }

  const tripData = tripSnapshot.data();

  if (!canManageTripInvitations(tripData, uid)) {
    throw new HttpsError(
      "permission-denied",
      "Only trip members can view invitation status.",
    );
  }

  if (!inviteSnapshot.exists) {
    return {
      status: "missing",
    };
  }

  const rawStatus =
      inviteSnapshot.data()?.status;

  return {
    status: rawStatus === "active" ?
      "active" :
      "revoked",
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
      coverUrl:
        typeof tripData?.coverUrl === "string" ? tripData.coverUrl : null,
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

  if (request.auth?.token.email_verified !== true) {
    throw new HttpsError(
      "failed-precondition",
      "A verified email address is required.",
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
  const hasAllergies = travellerProfile.hasAllergies;
  const hasIntolerances = travellerProfile.hasIntolerances;
  const hasMedicalAccessibilityInfo =
    travellerProfile.hasMedicalAccessibilityInfo;

  if (
    typeof hasEsimOrInternet !== "boolean" ||
    typeof hasCheckedBaggage !== "boolean" ||
    typeof hasCabinBaggage10Kg !== "boolean" ||
    typeof hasAllergies !== "boolean" ||
    typeof hasIntolerances !== "boolean" ||
    typeof hasMedicalAccessibilityInfo !== "boolean"
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

  if (
    hasAllergies &&
    (travellerProfile.allergies?.trim() ?? "").length === 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Allergy details are required when allergies are selected.",
    );
  }

  if (
    hasIntolerances &&
    (travellerProfile.intolerances?.trim() ?? "").length === 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Intolerance details are required when intolerances are selected.",
    );
  }

  if (
    hasMedicalAccessibilityInfo &&
    (
      travellerProfile.medicalAccessibilityInfo?.trim() ??
      ""
    ).length === 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Medical or accessibility details are required when selected.",
    );
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
        hasAllergies,
        hasIntolerances,
        hasMedicalAccessibilityInfo,
        allergies:
          hasAllergies ?
            travellerProfile.allergies?.trim() ?? "" :
            "",
        intolerances:
          hasIntolerances ?
            travellerProfile.intolerances?.trim() ?? "" :
            "",
        medicalAccessibilityInfo:
          hasMedicalAccessibilityInfo ?
            travellerProfile.medicalAccessibilityInfo?.trim() ?? "" :
            "",
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

export const listTripMembers = onCall(async (request) => {
  const uid = request.auth?.uid;

  if (uid == null) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication is required.",
    );
  }

  const rawTripId = request.data?.tripId;

  if (
    typeof rawTripId !== "string" ||
    rawTripId.trim().length === 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      "A valid tripId is required.",
    );
  }

  const tripId = rawTripId.trim();
  const tripRef = db.collection("trips").doc(tripId);
  const tripSnapshot = await tripRef.get();

  if (!tripSnapshot.exists) {
    throw new HttpsError(
      "not-found",
      "Trip not found.",
    );
  }

  const tripData = tripSnapshot.data();
  const memberUids = tripData?.memberUids;

  const isMember =
    tripData?.ownerUid === uid ||
    (
      Array.isArray(memberUids) &&
      memberUids.includes(uid)
    );

  if (!isMember) {
    throw new HttpsError(
      "permission-denied",
      "Trip membership is required.",
    );
  }

  const membersSnapshot =
    await tripRef.collection("members").get();

  const members = await Promise.all(
    membersSnapshot.docs.map(async (memberSnapshot) => {
      const memberData = memberSnapshot.data();
      const memberUid =
        typeof memberData.uid === "string" ?
          memberData.uid :
          memberSnapshot.id;

      const profileSnapshot = await db
        .collection("viaggiatori")
        .doc(memberUid)
        .get();

      const profileData = profileSnapshot.data();

      return {
        uid: memberUid,
        role:
          typeof memberData.role === "string" ?
            memberData.role :
            "traveler",
        joinedAt:
          memberData.joinedAt?.toMillis?.() ?? null,
        travellerProfileCompleted:
          memberData.travellerProfileCompleted === true,

        // Safe projection of the global profile.
        // Email, FCM token, Storage path and internal data are
        // intentionally NOT exposed to trip members.
        profile: {
          username:
            typeof profileData?.username === "string" ?
              profileData.username :
              "",
          firstName:
            typeof profileData?.firstName === "string" ?
              profileData.firstName :
              "",
          lastName:
            typeof profileData?.lastName === "string" ?
              profileData.lastName :
              "",
          photoUrl:
            typeof profileData?.photoUrl === "string" ?
              profileData.photoUrl :
              "",
        },

        travellerProfile:
          memberData.travellerProfile ?? null,
      };
    }),
  );

  return {
    tripId,
    members,
  };
});

export const updateMyTripTravellerProfile = onCall(
  async (request) => {
    const uid = request.auth?.uid;

    if (uid == null) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication is required.",
      );
    }

    const rawTripId = request.data?.tripId;
    const profile = request.data?.travellerProfile;

    if (
      typeof rawTripId !== "string" ||
      rawTripId.trim().length === 0
    ) {
      throw new HttpsError(
        "invalid-argument",
        "A valid tripId is required.",
      );
    }

    if (
      profile == null ||
      typeof profile !== "object" ||
      Array.isArray(profile)
    ) {
      throw new HttpsError(
        "invalid-argument",
        "A valid traveller profile is required.",
      );
    }

    const hasEsimOrInternet = profile.hasEsimOrInternet;
    const hasCheckedBaggage = profile.hasCheckedBaggage;
    const hasCabinBaggage10Kg =
      profile.hasCabinBaggage10Kg;
    const hasAllergies = profile.hasAllergies;
    const hasIntolerances = profile.hasIntolerances;
    const hasMedicalAccessibilityInfo =
      profile.hasMedicalAccessibilityInfo;

    if (
      typeof hasEsimOrInternet !== "boolean" ||
      typeof hasCheckedBaggage !== "boolean" ||
      typeof hasCabinBaggage10Kg !== "boolean" ||
      typeof hasAllergies !== "boolean" ||
      typeof hasIntolerances !== "boolean" ||
      typeof hasMedicalAccessibilityInfo !== "boolean"
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Traveller profile is incomplete.",
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
      const value = profile[field];

      if (value != null && typeof value !== "string") {
        throw new HttpsError(
          "invalid-argument",
          `Invalid traveller profile field: ${field}.`,
        );
      }
    }

    if (
      hasAllergies &&
      (profile.allergies?.trim() ?? "").length === 0
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Allergy details are required when allergies are selected.",
      );
    }

    if (
      hasIntolerances &&
      (profile.intolerances?.trim() ?? "").length === 0
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Intolerance details are required when intolerances are selected.",
      );
    }

    if (
      hasMedicalAccessibilityInfo &&
      (
        profile.medicalAccessibilityInfo?.trim() ??
        ""
      ).length === 0
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Medical or accessibility details are required when selected.",
      );
    }
    const tripId = rawTripId.trim();
    const tripRef = db.collection("trips").doc(tripId);
    const tripSnapshot = await tripRef.get();

    if (!tripSnapshot.exists) {
      throw new HttpsError(
        "not-found",
        "Trip not found.",
      );
    }

    const tripData = tripSnapshot.data();
    const memberUids = tripData?.memberUids;

    const isMember =
      tripData?.ownerUid === uid ||
      (
        Array.isArray(memberUids) &&
        memberUids.includes(uid)
      );

    if (!isMember) {
      throw new HttpsError(
        "permission-denied",
        "Trip membership is required.",
      );
    }

    const memberRef =
      tripRef.collection("members").doc(uid);

    const memberSnapshot = await memberRef.get();

    const memberRole =
      tripData?.ownerUid === uid ?
        "admin" :
        (
          typeof memberSnapshot.data()?.role === "string" ?
            memberSnapshot.data()?.role :
            "traveler"
        );

    await memberRef.set(
      {
        uid,
        role: memberRole,
        ...(memberSnapshot.exists ?
          {} :
          {joinedAt: FieldValue.serverTimestamp()}),
        travellerProfileCompleted: true,
        travellerProfile: {
          hasEsimOrInternet,
          hasCheckedBaggage,
          hasCabinBaggage10Kg,
          hasAllergies,
          hasIntolerances,
          hasMedicalAccessibilityInfo,
          allergies:
            hasAllergies ?
              profile.allergies?.trim() ?? "" :
              "",
          intolerances:
            hasIntolerances ?
              profile.intolerances?.trim() ?? "" :
              "",
          medicalAccessibilityInfo:
            hasMedicalAccessibilityInfo ?
              profile.medicalAccessibilityInfo?.trim() ?? "" :
              "",
          emergencyContactName:
            profile.emergencyContactName?.trim() ?? "",
          emergencyContactPhone:
            profile.emergencyContactPhone?.trim() ?? "",
        },
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    await tripRef.update({
      memberUids: FieldValue.arrayUnion(uid),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return {
      updated: true,
      tripId,
      uid,
    };
  },
);

export const removeTripMember = onCall(async (request) => {
  const uid = request.auth?.uid;

  if (uid == null) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication is required.",
    );
  }

  const rawTripId = request.data?.tripId;
  const rawTargetUid = request.data?.targetUid;

  if (
    typeof rawTripId !== "string" ||
    rawTripId.trim().length === 0 ||
    typeof rawTargetUid !== "string" ||
    rawTargetUid.trim().length === 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      "A valid tripId and targetUid are required.",
    );
  }

  const tripId = rawTripId.trim();
  const targetUid = rawTargetUid.trim();

  const tripRef = db.collection("trips").doc(tripId);
  const targetMemberRef =
    tripRef.collection("members").doc(targetUid);

  await db.runTransaction(async (transaction) => {
    const [tripSnapshot, targetMemberSnapshot] =
      await Promise.all([
        transaction.get(tripRef),
        transaction.get(targetMemberRef),
      ]);

    if (!tripSnapshot.exists) {
      throw new HttpsError(
        "not-found",
        "Trip not found.",
      );
    }

    const tripData = tripSnapshot.data();
    const memberUids = tripData?.memberUids;

    const callerIsMember =
      tripData?.ownerUid === uid ||
      (
        Array.isArray(memberUids) &&
        memberUids.includes(uid)
      );

    if (!callerIsMember) {
      throw new HttpsError(
        "permission-denied",
        "Trip membership is required.",
      );
    }

    if (tripData?.ownerUid === targetUid) {
      throw new HttpsError(
        "failed-precondition",
        "The trip owner cannot be removed.",
      );
    }

    if (!targetMemberSnapshot.exists) {
      throw new HttpsError(
        "not-found",
        "Trip member not found.",
      );
    }

    transaction.update(tripRef, {
      memberUids: FieldValue.arrayRemove(targetUid),
      updatedAt: FieldValue.serverTimestamp(),
    });

    transaction.delete(targetMemberRef);
  });

  return {
    removed: true,
    tripId,
    targetUid,
    leftTrip: targetUid === uid,
  };
});
export {
  setTripStatus,
} from "./trip-management/set-trip-status";

export {
  updateTripCloudArchive,
} from "./trip-management/update-trip-cloud-archive";

export {
  duplicateTrip,
} from "./trip-management/duplicate-trip";

export {
  deleteTrip,
} from "./trip-management/delete-trip";
