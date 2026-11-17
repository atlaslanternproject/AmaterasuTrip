import {randomBytes} from "crypto";

import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {hashInviteToken, canManageTripInvitations} from "./trip-invite-helpers";

const db = getFirestore();

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
