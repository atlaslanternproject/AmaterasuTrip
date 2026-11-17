import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";

const db = getFirestore();

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

    // Members may leave voluntarily.
    // Only the trip owner may remove another member.
    if (targetUid !== uid && tripData?.ownerUid !== uid) {
      throw new HttpsError(
        "permission-denied",
        "Only the trip owner can remove another member.",
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
