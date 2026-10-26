/* eslint-disable require-jsdoc, valid-jsdoc */
import {getFirestore} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";

import {planAccountDeletionTrips} from "./account-deletion-trip-inventory";

/**
 * Read-only account deletion inventory.
 *
 * This function does not remove memberships, delete accounts,
 * modify encryption keys, or authorise protected-data access.
 */
export const inspectAccountDeletionTrips = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = request.auth?.uid;

    if (typeof uid !== "string" || uid.length === 0) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication is required.",
      );
    }

    const db = getFirestore();

    const [ownedTrips, memberTrips] = await Promise.all([
      db.collection("trips").where("ownerUid", "==", uid).get(),
      db.collection("trips")
        .where("memberUids", "array-contains", uid)
        .get(),
    ]);

    return planAccountDeletionTrips(
      ownedTrips.docs.map((doc) => doc.id),
      memberTrips.docs.map((doc) => doc.id),
    );
  },
);
