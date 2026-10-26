/* eslint-disable require-jsdoc, valid-jsdoc */
import {
  FieldValue,
  Firestore,
} from "firebase-admin/firestore";

import type {
  AccountDeletionCleanupPort,
} from "./account-deletion-cleanup-orchestrator";

/**
 * Experimental Firestore adapter.
 *
 * NOT wired into account deletion or any production callable.
 * Membership deletion alone does NOT revoke E2EE keys.
 * Do not use until cryptographic revocation and deletion-state
 * coordination are implemented and tested.
 */
export class FirestoreAccountDeletionCleanupPort
implements AccountDeletionCleanupPort {
  constructor(private readonly db: Firestore) {}

  async listOwnedTripIds(uid: string): Promise<string[]> {
    this.requireIdentifier(uid, "UID");

    const snapshot = await this.db.collection("trips")
      .where("ownerUid", "==", uid)
      .get();

    return snapshot.docs.map((doc) => doc.id);
  }

  async listParticipatingTripIds(uid: string): Promise<string[]> {
    this.requireIdentifier(uid, "UID");

    const snapshot = await this.db.collection("trips")
      .where("memberUids", "array-contains", uid)
      .get();

    return snapshot.docs.map((doc) => doc.id);
  }

  async removeMembershipAtomically(
    tripId: string,
    uid: string,
  ): Promise<void> {
    this.requireIdentifier(tripId, "Trip ID");
    this.requireIdentifier(uid, "UID");

    const tripRef = this.db.collection("trips").doc(tripId);
    const memberRef = tripRef.collection("members").doc(uid);

    await this.db.runTransaction(async (transaction) => {
      // All reads occur before all writes.
      const trip = await transaction.get(tripRef);
      const member = await transaction.get(memberRef);

      if (!trip.exists) {
        throw new Error("Trip no longer exists.");
      }

      const data = trip.data();

      // This MUST be checked inside the transaction.
      if (data?.ownerUid === uid) {
        throw new Error(
          "Cannot remove a trip owner through membership cleanup.",
        );
      }

      const members = data?.memberUids;

      if (
        !Array.isArray(members) ||
        !members.includes(uid) ||
        !member.exists ||
        member.data()?.uid !== uid
      ) {
        throw new Error(
          "Inconsistent trip membership; deletion blocked.",
        );
      }

      transaction.update(tripRef, {
        memberUids: FieldValue.arrayRemove(uid),
        updatedAt: FieldValue.serverTimestamp(),
      });

      transaction.delete(memberRef);
    });
  }

  private requireIdentifier(
    value: string,
    name: string,
  ): void {
    if (
      typeof value !== "string" ||
      value.trim().length === 0 ||
      value.length > 128 ||
      value.includes("/") ||
      value === "." ||
      value === ".." ||
      [...value].some((ch) => ch.charCodeAt(0) < 32)
    ) {
      throw new Error(`Invalid ${name}.`);
    }
  }
}
