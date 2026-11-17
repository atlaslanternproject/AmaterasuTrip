import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {hashInviteToken} from "./trip-invite-helpers";

const db = getFirestore();

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

  if (request.data?.travellerProfile !== undefined) {
    throw new HttpsError(
      "invalid-argument",
      "The legacy traveller questionnaire is no longer supported.",
    );
  }

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
    });
  });

  return {
    accepted: true,
    tripId,
    role: "traveler",
  };
});
