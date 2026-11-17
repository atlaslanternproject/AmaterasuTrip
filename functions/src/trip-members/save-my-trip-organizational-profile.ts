import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";

const db = getFirestore();

export const saveMyTripOrganizationalProfile = onCall(
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign-in required.");
    }

    const tripId = request.data?.tripId;
    const input = request.data?.organizationalProfile;

    if (typeof tripId !== "string" || tripId.trim().length === 0) {
      throw new HttpsError("invalid-argument", "Invalid tripId.");
    }

    if (input === null || typeof input !== "object" ||
        Array.isArray(input)) {
      throw new HttpsError("invalid-argument", "Invalid profile.");
    }

    const allowed = [
      "hasEsimOrInternet",
      "hasCheckedBaggage",
      "hasCabinBaggage10Kg",
    ];

    const actual = Object.keys(input);

    if (actual.length !== allowed.length ||
        actual.some((key) => !allowed.includes(key))) {
      throw new HttpsError(
        "invalid-argument",
        "Only organizational answers are permitted.",
      );
    }

    for (const key of allowed) {
      if (typeof input[key] !== "boolean") {
        throw new HttpsError(
          "invalid-argument",
          "All organizational answers must be boolean.",
        );
      }
    }

    const profile = {
      hasEsimOrInternet: input.hasEsimOrInternet as boolean,
      hasCheckedBaggage: input.hasCheckedBaggage as boolean,
      hasCabinBaggage10Kg: input.hasCabinBaggage10Kg as boolean,
    };

    const tripRef = db.collection("trips").doc(tripId.trim());
    const memberRef = tripRef.collection("members").doc(uid);

    await db.runTransaction(async (transaction) => {
      const tripSnapshot = await transaction.get(tripRef);
      const memberSnapshot = await transaction.get(memberRef);

      if (!tripSnapshot.exists || !memberSnapshot.exists) {
        throw new HttpsError(
          "permission-denied",
          "Active trip membership required.",
        );
      }

      const tripData = tripSnapshot.data();
      const memberUids = tripData?.memberUids;

      const activeMember = tripData?.ownerUid === uid ||
        (Array.isArray(memberUids) && memberUids.includes(uid));

      if (!activeMember || memberSnapshot.data()?.uid !== uid) {
        throw new HttpsError(
          "permission-denied",
          "Active trip membership required.",
        );
      }

      transaction.update(memberRef, {
        organizationalProfile: profile,
        updatedAt: FieldValue.serverTimestamp(),
      });
    });

    return {
      updated: true,
      tripId: tripId.trim(),
      uid,
    };
  },
);
