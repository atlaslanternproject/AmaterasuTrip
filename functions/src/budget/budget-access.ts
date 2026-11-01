import {getFirestore, Transaction} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {validId} from "./budget-validation";

const db = getFirestore();

/**
 * Verifies active trip membership and returns active traveler IDs.
 *
 * @param {Transaction} transaction Firestore transaction.
 * @param {string} tripId Trip identifier.
 * @param {string} uid Authenticated user identifier.
 * @return {Promise<string[]>} Active traveler identifiers.
 */
export async function checkBudgetMembership(
  transaction: Transaction,
  tripId: string,
  uid: string,
): Promise<string[]> {
  const tripRef = db.collection("trips").doc(validId(tripId));
  const trip = await transaction.get(tripRef);

  if (!trip.exists) {
    throw new HttpsError("not-found", "Trip not found.");
  }

  const data = trip.data();
  const members = data?.memberUids;

  if (!Array.isArray(members) ||
      (data?.ownerUid !== uid && !members.includes(uid))) {
    throw new HttpsError("permission-denied", "Membership required.");
  }

  const active = [...new Set(
    [...members, data?.ownerUid].filter(
      (value): value is string => typeof value === "string",
    ),
  )];

  return active;
}
