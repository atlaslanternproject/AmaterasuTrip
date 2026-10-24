/* eslint-disable require-jsdoc, valid-jsdoc */
import {
  createPublicKey,
  verify as verifyEd25519,
} from "node:crypto";

import {
  deviceApprovalSigningBytes,
  verifyDeviceApproval,
  type DeviceApprovalClaimWire,
  type ExpectedDeviceApproval,
} from "./device-approval-verifier";

// Fail closed on malformed or unauthenticated proof material.
function invalid(): never {
  throw new Error("Invalid recovery device proof.");
}

function isRecord(
  value: unknown,
): value is Record<string, unknown> {
  return value !== null &&
    typeof value === "object" &&
    !Array.isArray(value);
}

function signatureBytes(value: unknown): Buffer {
  if (typeof value !== "string" ||
      !/^[A-Za-z0-9+/]+={0,2}$/.test(value)) {
    invalid();
  }

  const decoded = Buffer.from(value, "base64");

  if (decoded.length !== 64 ||
      decoded.toString("base64") !== value) {
    invalid();
  }

  return decoded;
}

// Checks the root signature first, then the new device signature.
// Does not consume a challenge or register a device.
export function verifyRecoveryDeviceProof(
  raw: unknown,
  trustedRootPublicKey: string,
  expected: ExpectedDeviceApproval,
  nowMs: number = Date.now(),
): DeviceApprovalClaimWire {
  if (!isRecord(raw) ||
      Object.keys(raw).length !== 2 ||
      !Object.prototype.hasOwnProperty.call(raw, "approval") ||
      !Object.prototype.hasOwnProperty.call(raw, "newDeviceSignature")) {
    invalid();
  }

  const claim = verifyDeviceApproval(
    raw.approval,
    trustedRootPublicKey,
    expected,
    nowMs,
  );

  const signature = signatureBytes(raw.newDeviceSignature);
  const signingPublic = Buffer.from(
    claim.newEd25519PublicKey,
    "base64",
  );

  const spki = Buffer.concat([
    Buffer.from("302a300506032b6570032100", "hex"),
    signingPublic,
  ]);

  try {
    const publicKey = createPublicKey({
      key: spki,
      format: "der",
      type: "spki",
    });

    if (!verifyEd25519(
      null,
      deviceApprovalSigningBytes(claim),
      publicKey,
      signature,
    )) {
      invalid();
    }
  } catch {
    invalid();
  }

  return claim;
}
