import {createPublicKey, verify} from "node:crypto";
import {HttpsError} from "firebase-functions/v2/https";

export interface AccessProofContext {
  uid: string;
  tripId: string;
  profileUid: string;
  deviceId: string;
}

/**
 * Reject invalid proof material. This function always throws.
 */
function invalid(): never {
  throw new HttpsError(
    "permission-denied",
    "Invalid E2EE device proof.",
  );
}

/**
 * Convert untrusted input into a JSON record.
 *
 * @param {unknown} value Untrusted input.
 * @return {Object} Validated record.
 */
function object(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" ||
      Array.isArray(value)) {
    return invalid();
  }
  return value as Record<string, unknown>;
}

/**
 * Decode canonical base64 with an exact byte length.
 *
 * @param {unknown} value Encoded bytes.
 * @param {number} length Required byte count.
 * @return {Buffer} Decoded bytes.
 */
function base64(value: unknown, length: number): Buffer {
  if (typeof value !== "string" ||
      !/^[A-Za-z0-9+/]+={0,2}$/.test(value)) {
    return invalid();
  }
  const decoded = Buffer.from(value, "base64");
  if (decoded.length !== length ||
      decoded.toString("base64") !== value) {
    return invalid();
  }
  return decoded;
}

/**
 * Verify a signed device-bound profile access request.
 *
 * The proof establishes signing-key possession, not entitlement
 * to decrypt health records.
 *
 * @param {unknown} input Untrusted proof.
 * @param {Object|undefined} root Registered first-root document.
 * @param {AccessProofContext} expected Authenticated identity context.
 * @param {number} nowMs Server timestamp.
 * @return {Object} Verified nonce for atomic replay prevention.
 */
export function verifyTripProfileAccessProof(
  input: unknown,
  root: Record<string, unknown> | undefined,
  expected: AccessProofContext,
  nowMs: number,
): {nonce: string} {
  const proof = object(input);
  const fields = [
    "uid", "tripId", "profileUid", "deviceId",
    "nonce", "issuedAtMs", "expiresAtMs", "signature",
  ];

  if (Object.keys(proof).length !== fields.length ||
      fields.some((key) =>
        !Object.prototype.hasOwnProperty.call(proof, key))) {
    return invalid();
  }

  if (proof.uid !== expected.uid ||
      proof.tripId !== expected.tripId ||
      proof.profileUid !== expected.profileUid ||
      proof.deviceId !== expected.deviceId ||
      !root ||
      root.userUid !== expected.uid ||
      root.deviceId !== expected.deviceId) {
    return invalid();
  }

  if (!Number.isSafeInteger(proof.issuedAtMs) ||
      !Number.isSafeInteger(proof.expiresAtMs) ||
      !Number.isSafeInteger(nowMs)) {
    return invalid();
  }

  const issuedAtMs = proof.issuedAtMs as number;
  const expiresAtMs = proof.expiresAtMs as number;

  if (expiresAtMs - issuedAtMs !== 120000 ||
      issuedAtMs > nowMs + 30000 ||
      nowMs > expiresAtMs) {
    return invalid();
  }

  const nonce = proof.nonce;
  if (typeof nonce !== "string" ||
      !/^[A-Za-z0-9_-]{43}$/.test(nonce)) {
    return invalid();
  }

  const nonceBytes = Buffer.from(nonce, "base64url");
  if (nonceBytes.length !== 32 ||
      nonceBytes.toString("base64url") !== nonce) {
    return invalid();
  }

  const publicBytes = base64(root.ed25519PublicKey, 32);
  const signature = base64(proof.signature, 64);

  const canonical = Buffer.from(JSON.stringify([
    "amaterasutrip",
    "trip-profile-access-request",
    1,
    expected.uid,
    expected.tripId,
    expected.profileUid,
    expected.deviceId,
    nonce,
    issuedAtMs,
    expiresAtMs,
  ]), "utf8");

  let valid = false;

  try {
    const key = createPublicKey({
      key: Buffer.concat([
        Buffer.from("302a300506032b6570032100", "hex"),
        publicBytes,
      ]),
      format: "der",
      type: "spki",
    });

    valid = verify(null, canonical, key, signature);
  } catch {
    valid = false;
  }

  if (!valid) {
    return invalid();
  }

  return {nonce};
}
