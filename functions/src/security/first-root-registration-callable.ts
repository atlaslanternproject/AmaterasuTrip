import {createHash, createPublicKey, verify} from "node:crypto";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {requireRecoveryCaller} from
  "./recovery-device-enrollment-callable";
import {registerFirstRootTransaction} from
  "./first-root-registration-transaction";

type FirstRootRecord = {
  version: number;
  userUid: string;
  deviceId: string;
  createdAtMs: number;
  x25519PublicKey: string;
  ed25519PublicKey: string;
  signature: string;
  fingerprint: string;
  recovery: {
    version: number;
    salt: string;
    nonce: string;
    ciphertext: string;
    mac: string;
  };
};

/**
 * Checks an untrusted JSON record.
 * @param {unknown} value Untrusted value.
 * @return {boolean} Whether it is an object.
 */
function isRecord(
  value: unknown,
): value is Record<string, unknown> {
  return value !== null &&
    typeof value === "object" &&
    !Array.isArray(value);
}

/**
 * Checks an exact record key set.
 * @param {Object} value JSON record.
 * @param {string[]} keys Expected keys.
 * @return {boolean} Exact key match.
 */
function exactKeys(
  value: Record<string, unknown>,
  keys: string[],
): boolean {
  return Object.keys(value).length === keys.length &&
    keys.every((key) =>
      Object.prototype.hasOwnProperty.call(value, key));
}

/**
 * Decodes canonical base64 with an exact byte length.
 * @param {unknown} value Untrusted encoded bytes.
 * @param {number} length Expected decoded byte length.
 * @return {Buffer|null} Canonical bytes or null.
 */
function canonicalBase64(
  value: unknown,
  length: number,
): Buffer | null {
  if (typeof value !== "string" ||
      !/^[A-Za-z0-9+/]+={0,2}$/.test(value)) {
    return null;
  }

  const bytes = Buffer.from(value, "base64");

  return bytes.length === length &&
    bytes.toString("base64") === value ? bytes : null;
}

/**
 * Validates a self-signed first-root identity and encrypted backup.
 * Self-signature alone does NOT prove account ownership.
 * Account and creation-history checks happen in the callable.
 *
 * @param {unknown} input Untrusted first-root record.
 * @param {string} uid Authenticated Firebase UID.
 * @param {number} nowMs Current server time.
 * @return {Object|null} Verified public record or null.
 */
export function validateFirstRootRecord(
  input: unknown,
  uid: string,
  nowMs: number,
): FirstRootRecord | null {
  if (!isRecord(input) ||
      !exactKeys(input, [
        "version", "userUid", "deviceId", "createdAtMs",
        "x25519PublicKey", "ed25519PublicKey",
        "signature", "fingerprint", "recovery",
      ]) ||
      input.version !== 1 ||
      input.userUid !== uid ||
      typeof input.deviceId !== "string" ||
      !/^[A-Za-z0-9_-]{43}$/.test(input.deviceId) ||
      typeof input.createdAtMs !== "number" ||
      !Number.isSafeInteger(input.createdAtMs) ||
      input.createdAtMs <= 0 ||
      input.createdAtMs > nowMs + 30000 ||
      input.createdAtMs < nowMs - 604800000 ||
      typeof input.fingerprint !== "string" ||
      !/^[A-Za-z0-9_-]{43}$/.test(input.fingerprint) ||
      !isRecord(input.recovery)) {
    return null;
  }

  const recovery = input.recovery;

  if (!exactKeys(recovery, [
    "version", "salt", "nonce", "ciphertext", "mac",
  ]) ||
      recovery.version !== 1 ||
      canonicalBase64(recovery.salt, 32) === null ||
      canonicalBase64(recovery.nonce, 12) === null ||
      canonicalBase64(recovery.ciphertext, 64) === null ||
      canonicalBase64(recovery.mac, 16) === null) {
    return null;
  }

  const exchange = canonicalBase64(input.x25519PublicKey, 32);
  const signing = canonicalBase64(input.ed25519PublicKey, 32);
  const signature = canonicalBase64(input.signature, 64);

  if (exchange === null ||
      signing === null ||
      signature === null ||
      exchange.every((value) => value === 0) ||
      signing.every((value) => value === 0)) {
    return null;
  }

  // Must match the Dart first-device trust-anchor format.
  const anchorBytes = Buffer.from(JSON.stringify([
    "amaterasutrip",
    "first-device-trust-anchor",
    1,
    uid,
    input.deviceId,
    input.x25519PublicKey,
    input.ed25519PublicKey,
    input.createdAtMs,
  ]), "utf8");

  const fingerprint = createHash("sha256")
    .update(anchorBytes)
    .digest("base64url");

  if (fingerprint !== input.fingerprint) {
    return null;
  }

  try {
    const spki = Buffer.concat([
      Buffer.from("302a300506032b6570032100", "hex"),
      signing,
    ]);

    const publicKey = createPublicKey({
      key: spki,
      format: "der",
      type: "spki",
    });

    if (!verify(null, anchorBytes, publicKey, signature)) {
      return null;
    }
  } catch {
    return null;
  }

  return {
    version: 1,
    userUid: uid,
    deviceId: input.deviceId,
    createdAtMs: input.createdAtMs,
    x25519PublicKey: input.x25519PublicKey as string,
    ed25519PublicKey: input.ed25519PublicKey as string,
    signature: input.signature as string,
    fingerprint: input.fingerprint,
    recovery: {
      version: 1,
      salt: recovery.salt as string,
      nonce: recovery.nonce as string,
      ciphertext: recovery.ciphertext as string,
      mac: recovery.mac as string,
    },
  };
}

/**
 * Server-authorised first-device registration.
 *
 * Existing accounts outside the fresh-registration window require
 * a separate verified migration. Never silently reinitialise roots.
 */
export const registerFirstE2eeRoot = onCall(
  {enforceAppCheck: true},
  async (request) => {
    const nowMs = Date.now();

    const uid = requireRecoveryCaller({
      uid: request.auth?.uid,
      emailVerified: request.auth?.token.email_verified,
      authTimeSeconds: request.auth?.token.auth_time,
      appCheckValid: request.app != null,
    }, nowMs);

    const data: unknown = request.data;

    if (!isRecord(data) ||
        !exactKeys(data, ["root"])) {
      throw new HttpsError(
        "invalid-argument",
        "Invalid first-root request.",
      );
    }

    const root = validateFirstRootRecord(
      data.root,
      uid,
      nowMs,
    );

    if (root === null) {
      throw new HttpsError(
        "invalid-argument",
        "Invalid signed first-root record.",
      );
    }

    // Use Firebase Auth Admin metadata, not a client timestamp.
    const account = await getAuth().getUser(uid);
    const createdAtMs = Date.parse(
      account.metadata.creationTime,
    );

    if (!account.emailVerified ||
        !Number.isSafeInteger(createdAtMs) ||
        createdAtMs > nowMs + 300000 ||
        nowMs - createdAtMs > 604800000 ||
        root.createdAtMs < createdAtMs - 300000) {
      throw new HttpsError(
        "failed-precondition",
        "Independent account-migration verification required.",
      );
    }

    await registerFirstRootTransaction(
      getFirestore(),
      uid,
      root,
      nowMs,
    );

    return {
      deviceId: root.deviceId,
      fingerprint: root.fingerprint,
    };
  },
);
