/* eslint-disable require-jsdoc, valid-jsdoc */
import {
  FieldValue,
  Firestore,
} from "firebase-admin/firestore";

import {
  planAccountDeletionTrips,
} from "./account-deletion-trip-inventory";

/**
 * Account deletion preflight.
 *
 * This is a server-side preparation component, not an
 * authorisation to delete Firebase Auth or user data.
 *
 * NO account deletion, membership removal, key revocation,
 * or protected profile access occurs here.
 *
 * Its persisted status is advisory only and MUST NOT
 * be used as proof that a user can safely be deleted.
 */
export class AccountDeletionPreflight {
  constructor(private readonly db: Firestore) {}

  async prepare(uid: string): Promise<{
    stage: string;
    ownedTripCount: number;
    participatingTripCount: number;
  }> {
    if (
      typeof uid !== "string" ||
      uid.trim().length === 0 ||
      uid.length > 128 ||
      uid.includes("/") ||
      uid === "." ||
      uid === ".." ||
      [...uid].some((character) => character.charCodeAt(0) < 32)
    ) {
      throw new Error("Invalid account UID.");
    }

    const tripsRef = this.db.collection("trips");

    const [ownedSnapshot, memberSnapshot] = await Promise.all([
      tripsRef.where("ownerUid", "==", uid).get(),
      tripsRef.where("memberUids", "array-contains", uid).get(),
    ]);

    const inventory = planAccountDeletionTrips(
      ownedSnapshot.docs.map((doc) => doc.id),
      memberSnapshot.docs.map((doc) => doc.id),
    );

    let stage: string;

    if (inventory.requiresOwnerResolution) {
      stage = "blocked_owner_resolution";
    } else if (inventory.requiresMembershipCleanup) {
      stage = "blocked_e2ee_revocation";
    } else {
      stage = "pending_other_data_cleanup";
    }

    // These counts and the stage are diagnostic metadata.
    // No medical information or cryptographic keys are stored.
    const record = {
      schemaVersion: 1,
      uid,
      stage,
      ownedTripCount: inventory.ownedTripIds.length,
      participatingTripCount:
        inventory.participatingTripIds.length,
      checkedAt: FieldValue.serverTimestamp(),
    };

    // Persistence does not make the inventory authoritative:
    // future deletion must recheck membership and key revocation.
    await this.db
      .collection("_amaterasuAccountDeletionPreflight")
      .doc(uid)
      .set(record);

    return {
      stage,
      ownedTripCount: record.ownedTripCount,
      participatingTripCount: record.participatingTripCount,
    };
  }
}
