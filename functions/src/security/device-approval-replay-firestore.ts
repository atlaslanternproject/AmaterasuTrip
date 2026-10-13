import {createHash} from "node:crypto";
import type {Firestore} from "firebase-admin/firestore";

/**
 * Atomic server-side replay ledger.
 *
 * This prevents duplicate consumption while Firestore is operating
 * honestly. A privileged administrator can remove ledger records:
 * this is NOT a defence against a malicious backend.
 *
 * Client-side pinning, persistent local replay protection,
 * device authorization and revocation remain mandatory.
 *
 * No live Firebase operation happens until this class is instantiated
 * and explicitly called by production code.
 */
export class FirestoreDeviceApprovalReplayLedger {
  constructor(
    private readonly firestore: Firestore,
    private readonly clock: () => number = () => Date.now(),
  ) {}

  async consumeIfUnused(args: {
    userUid: string;
    challenge: string;
    expiresAtMs: number;
  }): Promise<boolean> {
    const {userUid, challenge, expiresAtMs} = args;

    if (
      typeof userUid !== "string" ||
      !/^[A-Za-z0-9_-]{1,128}$/.test(userUid) ||
      typeof challenge !== "string" ||
      !/^[A-Za-z0-9+/]{43}=$/.test(challenge) ||
      !Number.isSafeInteger(expiresAtMs)
    ) {
      throw new Error("Invalid device approval replay context.");
    }

    const bytes = Buffer.from(challenge, "base64");

    if (
      bytes.length !== 32 ||
      bytes.toString("base64") !== challenge ||
      bytes.every((byte) => byte === 0)
    ) {
      throw new Error("Invalid device approval replay challenge.");
    }

    const now = this.clock();

    if (
      !Number.isSafeInteger(now) ||
      now <= 0 ||
      expiresAtMs <= now ||
      expiresAtMs - now > 330000
    ) {
      throw new Error("Device approval replay request expired or invalid.");
    }

    // Domain separation and account binding.
    // Neither the raw challenge nor the UID is stored in the record.
    const id = createHash("sha256")
      .update("amaterasu-device-approval-replay-v1\0", "utf8")
      .update(userUid, "utf8")
      .update(Buffer.from([0]))
      .update(bytes)
      .digest("hex");

    const reference = this.firestore
      .collection("deviceApprovalReplayV1")
      .doc(id);

    try {
      // Atomic create-if-absent.
      // Never use a separate read followed by set().
      await reference.create({
        version: 1,
        consumedAtMs: now,
        expiresAtMs,
      });

      return true;
    } catch (error: unknown) {
      const code =
        error !== null && typeof error === "object" &&
        "code" in error ? error.code : undefined;

      if (
        code === 6 ||
        code === "already-exists" ||
        code === "ALREADY_EXISTS"
      ) {
        return false;
      }

      // Network failure, permission failure or uncertain write status:
      // fail closed. The caller must not grant authorization.
      throw error;
    }
  }
}