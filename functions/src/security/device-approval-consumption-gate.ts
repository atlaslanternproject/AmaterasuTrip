/* eslint-disable require-jsdoc, valid-jsdoc */
import {
  verifyDeviceApproval,
  type ExpectedDeviceApproval,
} from "./device-approval-verifier";

/**
 * An authenticated, atomic replay ledger.
 * A Firebase-backed implementation does not defend against a
 * malicious administrator who can delete or roll back records.
 */
export interface DeviceApprovalReplayLedger {
  consumeIfUnused(args: {
    userUid: string;
    challenge: string;
    expiresAtMs: number;
  }): Promise<boolean>;
}

/**
 * Verifies the approval BEFORE consuming its one-time challenge.
 *
 * This gate DOES NOT:
 * - establish trust in the approver public key;
 * - establish the expected context;
 * - register or authorise devices;
 * - grant access to traveller data;
 * - protect against backend rollback or key substitution.
 *
 * Those requirements must be enforced independently.
 */
export class DeviceApprovalConsumptionGate {
  constructor(
    private readonly ledger: DeviceApprovalReplayLedger,
    private readonly clock: () => number = () => Date.now(),
  ) {}

  async verifyAndConsume(args: {
    approval: unknown;
    trustedApproverEd25519PublicKey: string;
    expected: ExpectedDeviceApproval;
  }): Promise<void> {
    const nowMs = this.clock();

    // Fail closed before any ledger write if the signature,
    // trusted-key context or timestamp is invalid.
    const verified = verifyDeviceApproval(
      args.approval,
      args.trustedApproverEd25519PublicKey,
      args.expected,
      nowMs,
    );

    const firstUse = await this.ledger.consumeIfUnused({
      userUid: verified.userUid,
      challenge: verified.challenge,
      expiresAtMs: verified.expiresAtMs,
    });

    if (!firstUse) {
      throw new Error("Device approval challenge already consumed.");
    }
  }
}
