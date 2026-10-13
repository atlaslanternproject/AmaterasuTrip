import {createPublicKey, verify as verifyEd25519} from "node:crypto";

/**
 * Standalone verification of the Dart DeviceApprovalClaim signing format.
 *
 * IMPORTANT:
 * - The trusted Ed25519 key must be established independently.
 * - Expected context must not be copied blindly from the claim.
 * - This verification does not grant membership or device trust.
 * - Replay prevention requires a separate atomic, durable ledger.
 */
export interface DeviceApprovalClaimWire {
  userUid: string;
  approverDeviceId: string;
  newDeviceId: string;
  newX25519PublicKey: string;
  newEd25519PublicKey: string;
  challenge: string;
  issuedAtMs: number;
  expiresAtMs: number;
}

export interface ExpectedDeviceApproval {
  userUid: string;
  approverDeviceId: string;
  newDeviceId: string;
  newX25519PublicKey: string;
  newEd25519PublicKey: string;
  challenge: string;
}

const maximumLifetimeMs = 5 * 60 * 1000;
const allowedClockSkewMs = 30 * 1000;

function invalid(): never {
  throw new Error("Invalid signed device approval.");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null &&
    typeof value === "object" &&
    !Array.isArray(value);
}

function exactKeys(
  record: Record<string, unknown>,
  expected: string[],
): void {
  const keys = Object.keys(record);
  if (
    keys.length !== expected.length ||
    keys.some((key) => !expected.includes(key))
  ) {
    invalid();
  }
}

function identifier(value: unknown): string {
  if (
    typeof value !== "string" ||
    !/^[A-Za-z0-9_-]{1,128}$/.test(value)
  ) {
    invalid();
  }
  return value as string;
}

function integer(value: unknown): number {
  if (
    typeof value !== "number" ||
    !Number.isSafeInteger(value)
  ) {
    invalid();
  }
  return value as number;
}

function canonicalBytes(value: unknown, expectedLength: number): Buffer {
  if (
    typeof value !== "string" ||
    value.length === 0 ||
    value.length > 128 ||
    !/^[A-Za-z0-9+/]+={0,2}$/.test(value)
  ) {
    invalid();
  }

  const bytes = Buffer.from(value as string, "base64");

  if (
    bytes.length !== expectedLength ||
    bytes.toString("base64") !== value ||
    bytes.every((byte) => byte === 0)
  ) {
    invalid();
  }

  return bytes;
}

/**
 * The byte sequence exactly matches Dart:
 *
 * utf8.encode(jsonEncode([
 *   'amaterasutrip', 'device-approval', 1,
 *   userUid, approverDeviceId, newDeviceId,
 *   base64(newX25519), base64(newEd25519), base64(challenge),
 *   issuedAtMs, expiresAtMs
 * ]))
 */
export function deviceApprovalSigningBytes(
  claim: DeviceApprovalClaimWire,
): Buffer {
  return Buffer.from(JSON.stringify([
    "amaterasutrip",
    "device-approval",
    1,
    claim.userUid,
    claim.approverDeviceId,
    claim.newDeviceId,
    claim.newX25519PublicKey,
    claim.newEd25519PublicKey,
    claim.challenge,
    claim.issuedAtMs,
    claim.expiresAtMs,
  ]), "utf8");
}

/**
 * Validates a signed approval using an independently trusted public key.
 *
 * An actual integration must pass server-controlled time and context
 * authenticated through the pending-device enrolment workflow.
 */
export function verifyDeviceApproval(
  raw: unknown,
  trustedApproverEd25519PublicKey: string,
  expected: ExpectedDeviceApproval,
  nowMs: number = Date.now(),
): DeviceApprovalClaimWire {
  if (!isRecord(raw)) invalid();

  exactKeys(raw, ["claim", "signature"]);

  if (!isRecord(raw.claim)) invalid();

  const input = raw.claim;

  exactKeys(input, [
    "userUid",
    "approverDeviceId",
    "newDeviceId",
    "newX25519PublicKey",
    "newEd25519PublicKey",
    "challenge",
    "issuedAtMs",
    "expiresAtMs",
  ]);

  if (!isRecord(expected)) invalid();

  exactKeys(expected, [
    "userUid",
    "approverDeviceId",
    "newDeviceId",
    "newX25519PublicKey",
    "newEd25519PublicKey",
    "challenge",
  ]);

  const claim: DeviceApprovalClaimWire = {
    userUid: identifier(input.userUid),
    approverDeviceId: identifier(input.approverDeviceId),
    newDeviceId: identifier(input.newDeviceId),
    newX25519PublicKey:
      canonicalBytes(input.newX25519PublicKey, 32).toString("base64"),
    newEd25519PublicKey:
      canonicalBytes(input.newEd25519PublicKey, 32).toString("base64"),
    challenge: canonicalBytes(input.challenge, 32).toString("base64"),
    issuedAtMs: integer(input.issuedAtMs),
    expiresAtMs: integer(input.expiresAtMs),
  };

  const timestamp = integer(nowMs);
  const lifetime = claim.expiresAtMs - claim.issuedAtMs;

  if (
    claim.approverDeviceId === claim.newDeviceId ||
    claim.issuedAtMs <= 0 ||
    lifetime <= 0 ||
    lifetime > maximumLifetimeMs ||
    timestamp >= claim.expiresAtMs ||
    claim.issuedAtMs > timestamp + allowedClockSkewMs
  ) {
    invalid();
  }

  if (
    claim.userUid !== identifier(expected.userUid) ||
    claim.approverDeviceId !== identifier(expected.approverDeviceId) ||
    claim.newDeviceId !== identifier(expected.newDeviceId) ||
    claim.newX25519PublicKey !==
      canonicalBytes(expected.newX25519PublicKey, 32).toString("base64") ||
    claim.newEd25519PublicKey !==
      canonicalBytes(expected.newEd25519PublicKey, 32).toString("base64") ||
    claim.challenge !==
      canonicalBytes(expected.challenge, 32).toString("base64")
  ) {
    invalid();
  }

  const signature = canonicalBytes(raw.signature, 64);
  const publicKey = canonicalBytes(
    trustedApproverEd25519PublicKey,
    32
  );

  // Standard Ed25519 SubjectPublicKeyInfo prefix followed by 32 raw bytes.
  const spki = Buffer.concat([
    Buffer.from("302a300506032b6570032100", "hex"),
    publicKey,
  ]);

  try {
    const key = createPublicKey({
      key: spki,
      format: "der",
      type: "spki",
    });

    const valid = verifyEd25519(
      null,
      deviceApprovalSigningBytes(claim),
      key,
      signature,
    );

    if (!valid) invalid();
  } catch (_) {
    invalid();
  }

  return claim;
}