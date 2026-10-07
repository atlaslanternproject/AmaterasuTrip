import {DocumentData} from "firebase-admin/firestore";

/**
 * Checks whether the authenticated user belongs to a trip.
 *
 * During the current Amaterasu phase OWNER and TRAVELER are
 * intentionally equivalent for management operations.
 *
 * @param {Object|undefined} tripData Firestore trip data.
 * @param {string} uid Authenticated user UID.
 * @return {boolean} Whether the user belongs to the trip.
 */
export function isTripMember(
  tripData: DocumentData | undefined,
  uid: string,
): boolean {
  if (tripData?.ownerUid === uid) {
    return true;
  }

  const memberUids = tripData?.memberUids;

  return Array.isArray(memberUids) &&
    memberUids.includes(uid);
}
