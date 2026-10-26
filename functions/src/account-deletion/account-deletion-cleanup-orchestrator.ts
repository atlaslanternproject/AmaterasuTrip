/* eslint-disable require-jsdoc, valid-jsdoc */
import {
  planAccountDeletionTrips,
} from "./account-deletion-trip-inventory";

/**
 * Experimental account-deletion cleanup orchestration.
 *
 * NOT connected to a production callable.
 * The storage adapter must independently enforce atomic ownership checks,
 * authenticated identity, membership restrictions and E2EE revocation.
 */
export interface AccountDeletionCleanupPort {
  listOwnedTripIds(uid: string): Promise<string[]>;
  listParticipatingTripIds(uid: string): Promise<string[]>;
  removeMembershipAtomically(
    tripId: string,
    uid: string,
  ): Promise<void>;
}

export class AccountDeletionOwnerResolutionRequired extends Error {
  constructor() {
    super("Owned trips require resolution before account deletion.");
    this.name = "AccountDeletionOwnerResolutionRequired";
  }
}

export interface AccountDeletionCleanupResult {
  removedTripIds: string[];
  remainingReferences: number;
}

export async function cleanupAccountTripMemberships(
  store: AccountDeletionCleanupPort,
  uid: string,
): Promise<AccountDeletionCleanupResult> {
  if (
    typeof uid !== "string" ||
    uid.trim().length === 0 ||
    uid.length > 128 ||
    [...uid].some((character) => character.charCodeAt(0) < 32)
  ) {
    throw new Error("Invalid authenticated account UID.");
  }

  // Preflight: never start removals while this account owns a trip.
  const inventory = planAccountDeletionTrips(
    await store.listOwnedTripIds(uid),
    await store.listParticipatingTripIds(uid),
  );

  if (inventory.requiresOwnerResolution) {
    throw new AccountDeletionOwnerResolutionRequired();
  }

  const removedTripIds: string[] = [];

  for (const tripId of inventory.participatingTripIds) {
    // The adapter MUST recheck ownership inside its Firestore transaction.
    // An earlier preflight query is not an authorisation guarantee.
    await store.removeMembershipAtomically(tripId, uid);
    removedTripIds.push(tripId);
  }

  // Fail closed: the account must remain intact if references persist.
  const remaining = planAccountDeletionTrips(
    await store.listOwnedTripIds(uid),
    await store.listParticipatingTripIds(uid),
  );

  if (
    remaining.requiresOwnerResolution ||
    remaining.requiresMembershipCleanup
  ) {
    throw new Error(
      "Trip references remain after membership cleanup.",
    );
  }

  return {
    removedTripIds,
    remainingReferences: 0,
  };
}
