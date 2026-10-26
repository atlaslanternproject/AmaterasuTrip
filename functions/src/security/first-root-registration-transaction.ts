import {Firestore} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";

/**
 * Atomically registers an immutable first root and its history ledger.
 *
 * The caller must first verify authentication, account eligibility,
 * the root signature, the fingerprint and the recovery envelope.
 *
 * Both documents are created in one Firestore transaction.
 * A root or ledger that already exists blocks registration.
 *
 * @param {Firestore} db Firestore instance.
 * @param {string} uid Authenticated Firebase UID.
 * @param {Object} root Validated public root and encrypted backup.
 * @param {number} nowMs Server registration timestamp.
 * @return {Promise<void>} Atomic transaction completion.
 */
export async function registerFirstRootTransaction(
  db: Firestore,
  uid: string,
  root: Record<string, unknown>,
  nowMs: number,
): Promise<void> {
  if (typeof uid !== "string" ||
      uid.length === 0 ||
      root.version !== 1 ||
      root.userUid !== uid ||
      typeof root.deviceId !== "string" ||
      root.deviceId.length === 0 ||
      typeof root.fingerprint !== "string" ||
      root.fingerprint.length === 0 ||
      !Number.isSafeInteger(nowMs) ||
      nowMs <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid first-root transaction context.",
    );
  }

  const rootRef = db.collection("e2eeRoots").doc(uid);

  const ledgerRef = db.collection(
    "e2eeRootCreationLedgerV1",
  ).doc(uid);

  await db.runTransaction(async (transaction) => {
    // All reads must precede the first write.
    const [existingRoot, existingLedger] =
      await Promise.all([
        transaction.get(rootRef),
        transaction.get(ledgerRef),
      ]);

    // Historical ledger also blocks re-registration if the
    // original root document has been removed.
    if (existingRoot.exists || existingLedger.exists) {
      throw new HttpsError(
        "already-exists",
        "An account root has already been registered.",
      );
    }

    transaction.create(rootRef, root);

    transaction.create(ledgerRef, {
      version: 1,
      userUid: uid,
      deviceId: root.deviceId,
      rootFingerprint: root.fingerprint,
      registeredAtMs: nowMs,
    });
  });
}
