import {getFirestore} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";

const db = getFirestore();

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

  // Do not project orphan member documents that are no longer referenced
  // by the authoritative trip membership list.
  const activeUids = new Set<string>(
    Array.isArray(memberUids) ?
      memberUids.filter((value): value is string => typeof value === "string") :
      [],
  );
  if (typeof tripData?.ownerUid === "string") {
    activeUids.add(tripData.ownerUid);
  }

  const members = await Promise.all(
    membersSnapshot.docs
      .filter((memberSnapshot) => activeUids.has(memberSnapshot.id))
      .map(async (memberSnapshot) => {
        const memberData = memberSnapshot.data();
        const memberUid = memberSnapshot.id;

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

          // Only these three non-medical answers may be shared.
          // The caller has already passed the trip membership check.
          organizationalProfile: (() => {
            const value = memberData.organizationalProfile;

            if (!value || typeof value !== "object" ||
                Array.isArray(value)) {
              return null;
            }

            if (typeof value.hasEsimOrInternet !== "boolean" ||
                typeof value.hasCheckedBaggage !== "boolean" ||
                typeof value.hasCabinBaggage10Kg !== "boolean") {
              return null;
            }

            return {
              hasEsimOrInternet: value.hasEsimOrInternet,
              hasCheckedBaggage: value.hasCheckedBaggage,
              hasCabinBaggage10Kg: value.hasCabinBaggage10Kg,
            };
          })(),

        };
      }),
  );

  return {
    tripId,
    members,
  };
});
