import {createHash} from "crypto";

/**
 * Creates the SHA-256 hash stored for an invitation token.
 *
 * @param {string} token Raw invitation token.
 * @return {string} SHA-256 hexadecimal hash.
 */
export function hashInviteToken(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}

/**
 * Checks whether a trip member can manage invitation links.
 *
 * Client permissions are exposed through TripAccessPolicy.
 * Cloud Functions enforce the same current membership rule
 * because client-side checks are not a security boundary.
 *
 * @param {Object|undefined} tripData Trip document data.
 * @param {string} uid Authenticated user UID.
 * @return {boolean} Whether the member can manage invitations.
 */
export function canManageTripInvitations(
  tripData: {
    ownerUid?: unknown;
    memberUids?: unknown;
  } | undefined,
  uid: string,
): boolean {
  if (tripData?.ownerUid === uid) {
    return true;
  }

  const memberUids = tripData?.memberUids;

  return Array.isArray(memberUids) &&
    memberUids.includes(uid);
}
