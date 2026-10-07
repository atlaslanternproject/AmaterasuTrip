import {
  FieldValue,
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

export const setTripStatus = onCall(
  {
    region: "europe-west1",
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

    const rawStatus =
      request.data?.status;

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
      rawStatus !== "active" &&
      rawStatus !== "closed"
    ) {
      throw new HttpsError(
        "invalid-argument",
        "A valid trip status is required.",
      );
    }

    const tripId =
      rawTripId.trim();

    const tripRef =
      db.collection("trips").doc(tripId);

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

    await tripRef.update({
      status: rawStatus,
      updatedAt:
        FieldValue.serverTimestamp(),
    });

    return {
      updated: true,
      tripId,
      status: rawStatus,
    };
  },
);
