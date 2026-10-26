/* eslint-disable require-jsdoc, valid-jsdoc */
export interface AccountDeletionTripInventory {
  ownedTripIds: string[];
  participatingTripIds: string[];
  requiresOwnerResolution: boolean;
  requiresMembershipCleanup: boolean;
}

export function planAccountDeletionTrips(
  ownedTripIds: string[],
  memberTripIds: string[],
): AccountDeletionTripInventory {
  for (const id of [...ownedTripIds, ...memberTripIds]) {
    if (typeof id !== "string" || id.trim().length === 0) {
      throw new Error("Invalid trip reference.");
    }
  }

  const owned = [...new Set(ownedTripIds)].sort();
  const ownedSet = new Set(owned);

  const participating = [...new Set(memberTripIds)]
    .filter((id) => !ownedSet.has(id))
    .sort();

  return {
    ownedTripIds: owned,
    participatingTripIds: participating,
    requiresOwnerResolution: owned.length > 0,
    requiresMembershipCleanup: participating.length > 0,
  };
}
