import {getFirestore} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {canManageTripInvitations} from "./trip-invite-helpers";

const db = getFirestore();

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
