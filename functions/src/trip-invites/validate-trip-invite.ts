import {getFirestore} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {hashInviteToken} from "./trip-invite-helpers";

const db = getFirestore();

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
