import {createHash} from "node:crypto";
import type {Firestore} from "firebase-admin/firestore";
import {verifyRecoveryDeviceProof} from
  "./device-recovery-proof-verifier";

// This is NOT a callable endpoint.
// The caller must enforce authentication, recent sign-in
// and App Check before invoking register().
const deviceIdPattern = /^[A-Za-z0-9_-]{43}$/;

/**
 * Rejects an invalid recovery request.
 */
function invalid(): never {
  throw new Error("Recovery device enrollment rejected.");
}

/**
 * Checks whether a value is a record.
 * @param {unknown} value Value to inspect.
 * @return {boolean} True for plain record-shaped objects.
 */
function record(value: unknown): value is Record<string, unknown> {
  return value !== null &&
    typeof value === "object" &&
    !Array.isArray(value);
}

/**
 * Checks a canonical 32-byte public key.
 * @param {unknown} value Untrusted key.
 * @return {boolean} Whether its encoding and length are valid.
 */
function canonicalKey(value: unknown): value is string {
  if (typeof value !== "string" ||
      !/^[A-Za-z0-9+/]{43}=$/.test(value)) {
    return false;
  }

  const bytes = Buffer.from(value, "base64");
  return bytes.length === 32 &&
    bytes.toString("base64") === value;
}

/**
 * Extracts the untrusted approval claim.
 * @param {unknown} proof Submitted proof.
 * @return {Object} Untrusted claim requiring signature verification.
 */
function claimFromProof(proof: unknown): Record<string, unknown> {
  if (!record(proof) ||
      !record(proof.approval) ||
      !record(proof.approval.claim)) {
    invalid();
  }

  return proof.approval.claim;
}

/**
 * Registers a recovered browser and consumes its challenge
 * in the SAME Firestore transaction.
 *
 * No private key or recovery code reaches this service.
 */
/**
 * Performs atomic enrollment and replay consumption.
 */
export class RecoveryDeviceEnrollmentTransaction {
  /**
   * Creates an enrollment transaction service.
   * @param {Firestore} db Firebase Admin Firestore.
   * @param {Function} clock Server clock.
   */
  constructor(
    private readonly db: Firestore,
    private readonly clock: () => number = () => Date.now(),
  ) {}

  /**
   * Verifies both signatures and registers the new device atomically.
   * @param {Object} args Authenticated UID and untrusted proof.
   * @return {Promise<Object>} Registered device identifier.
   */
  async register(args: {
    authenticatedUid: string;
    proof: unknown;
  }): Promise<{deviceId: string}> {
    const {authenticatedUid: uid, proof} = args;
    const claim = claimFromProof(proof);
    const nowMs = this.clock();

    if (!/^[A-Za-z0-9_-]{1,128}$/.test(uid) ||
        !Number.isSafeInteger(nowMs) ||
        nowMs <= 0 ||
        typeof claim.newDeviceId !== "string" ||
        !deviceIdPattern.test(claim.newDeviceId)) {
      invalid();
    }

    const rootRef = this.db
      .collection("e2eeRoots")
      .doc(uid);

    const newDeviceRef = this.db
      .collection("e2eeDevices")
      .doc(uid)
      .collection("devices")
      .doc(claim.newDeviceId);

    return this.db.runTransaction(async (tx) => {
      const rootSnapshot = await tx.get(rootRef);
      const root = rootSnapshot.data();

      if (!rootSnapshot.exists ||
          !record(root) ||
          root.version !== 1 ||
          root.userUid !== uid ||
          typeof root.deviceId !== "string" ||
          !deviceIdPattern.test(root.deviceId) ||
          !canonicalKey(root.ed25519PublicKey)) {
        invalid();
      }

      // The root public key is taken from the registered
      // server record, never from the submitted proof.
      const verified = verifyRecoveryDeviceProof(
        proof,
        root.ed25519PublicKey,
        {
          userUid: uid,
          approverDeviceId: root.deviceId,
          newDeviceId: claim.newDeviceId as string,
          newX25519PublicKey:
            claim.newX25519PublicKey as string,
          newEd25519PublicKey:
            claim.newEd25519PublicKey as string,
          challenge: claim.challenge as string,
        },
        nowMs,
      );

      // Same replay identifier as the existing
      // deviceApprovalReplayV1 ledger.
      const challengeBytes = Buffer.from(
        verified.challenge,
        "base64",
      );

      const replayId = createHash("sha256")
        .update("amaterasu-device-approval-replay-v1\0", "utf8")
        .update(uid, "utf8")
        .update(Buffer.from([0]))
        .update(challengeBytes)
        .digest("hex");

      const replayRef = this.db
        .collection("deviceApprovalReplayV1")
        .doc(replayId);

      // Every read is performed before the first write.
      const deviceSnapshot = await tx.get(newDeviceRef);
      const replaySnapshot = await tx.get(replayRef);

      if (deviceSnapshot.exists || replaySnapshot.exists) {
        invalid();
      }

      // Public keys only. Never store recovered private keys.
      tx.create(newDeviceRef, {
        version: 1,
        userUid: uid,
        deviceId: verified.newDeviceId,
        x25519PublicKey: verified.newX25519PublicKey,
        ed25519PublicKey: verified.newEd25519PublicKey,
        authorisedByRootDeviceId: root.deviceId,
        authorisedAtMs: nowMs,
        revokedAtMs: null,
      });

      // Challenge consumption is atomic with registration.
      tx.create(replayRef, {
        version: 1,
        consumedAtMs: nowMs,
        expiresAtMs: verified.expiresAtMs,
      });

      return {deviceId: verified.newDeviceId};
    });
  }
}
