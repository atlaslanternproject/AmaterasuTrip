import {
  getFirestore,
} from "firebase-admin/firestore";

import {
  HttpsError,
  onCall,
} from "firebase-functions/v2/https";

import {
  isTripMember,
} from "../shared/trip-access";

const db = getFirestore();

export const deleteTrip = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 300,
  },
  async (request) => {
    const uid = request.auth?.uid;

    if (uid == null) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication is required.",
      );
    }

    const rawTripId =
      request.data?.tripId;

    const confirmationName =
      request.data?.confirmationName;

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
      typeof confirmationName !== "string"
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Trip name confirmation is required.",
      );
    }

    const tripId =
      rawTripId.trim();

    const tripRef =
      db.collection("trips").doc(
        tripId,
      );

    const tripSnapshot =
      await tripRef.get();

    if (!tripSnapshot.exists) {
      throw new HttpsError(
        "not-found",
        "Trip not found.",
      );
    }

    const tripData =
      tripSnapshot.data();

    if (!isTripMember(tripData, uid)) {
      throw new HttpsError(
        "permission-denied",
        "Trip membership is required.",
      );
    }

    if (
      typeof tripData?.name !== "string" ||
      tripData.name !== confirmationName
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Trip name confirmation does not match.",
      );
    }

    const subcollections =
      await tripRef.listCollections();

    for (
      const collectionRef
      of subcollections
    ) {
      await db.recursiveDelete(
        collectionRef,
      );
    }

    const inviteRef =
      db.collection("tripInvites")
        .doc(tripId);

    const batch =
      db.batch();

    batch.delete(inviteRef);
    batch.delete(tripRef);

    await batch.commit();

    return {
      deleted: true,
      tripId,
    };
  },
);
