import {getFirestore} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {RecoveryDeviceEnrollmentTransaction} from
  "./recovery-device-enrollment-transaction";

/**
 * Checks a trusted Firebase authentication context.
 *
 * @param {Object} context Verified authentication information.
 * @param {number} nowMs Server timestamp in milliseconds.
 * @return {string} Authenticated account UID.
 */
export function requireRecoveryCaller(context: {
  uid: unknown;
  emailVerified: unknown;
  authTimeSeconds: unknown;
  appCheckValid: boolean;
}, nowMs: number): string {
  const {uid, emailVerified, authTimeSeconds, appCheckValid} = context;

  if (typeof uid !== "string" ||
      !/^[A-Za-z0-9_-]{1,128}$/.test(uid) ||
      emailVerified !== true ||
      appCheckValid !== true ||
      typeof authTimeSeconds !== "number" ||
      !Number.isSafeInteger(authTimeSeconds) ||
      !Number.isSafeInteger(nowMs)) {
    throw new HttpsError(
      "unauthenticated",
      "Recent verified login required.",
    );
  }

  const authenticatedAt = authTimeSeconds * 1000;

  if (!Number.isSafeInteger(authenticatedAt) ||
      authenticatedAt > nowMs + 30000 ||
      nowMs - authenticatedAt > 300000) {
    throw new HttpsError(
      "unauthenticated",
      "Please sign in again.",
    );
  }

  return uid;
}

/**
 * Protected callable candidate.
 *
 * Not exported by index.ts: no production deployment yet.
 * Requires client App Check and local key storage integration.
 */
export const recoveryDeviceEnrollmentCandidate = onCall(
  {enforceAppCheck: true},
  async (request) => {
    const uid = requireRecoveryCaller({
      uid: request.auth?.uid,
      emailVerified: request.auth?.token.email_verified,
      authTimeSeconds: request.auth?.token.auth_time,
      appCheckValid: request.app != null,
    }, Date.now());

    const data: unknown = request.data;

    if (data === null ||
        typeof data !== "object" ||
        Array.isArray(data) ||
        Object.keys(data).length !== 1 ||
        !Object.prototype.hasOwnProperty.call(data, "proof")) {
      throw new HttpsError(
        "invalid-argument",
        "Invalid recovery request.",
      );
    }

    const proof = (data as {proof: unknown}).proof;

    try {
      return await new RecoveryDeviceEnrollmentTransaction(
        getFirestore(),
      ).register({
        authenticatedUid: uid,
        proof,
      });
    } catch {
      // Never log private keys, recovery secrets or proof payloads.
      throw new HttpsError(
        "permission-denied",
        "Device recovery rejected.",
      );
    }
  },
);

/**
 * Confirms an existing recovery-device registration.
 *
 * Requires a verified recent Firebase login and valid App Check.
 * Does not approve devices, update records or return private keys.
 */
export const recoveryDeviceEnrollmentStatus = onCall(
  {enforceAppCheck: true},
  async (request) => {
    const uid = requireRecoveryCaller({
      uid: request.auth?.uid,
      emailVerified: request.auth?.token.email_verified,
      authTimeSeconds: request.auth?.token.auth_time,
      appCheckValid: request.app != null,
    }, Date.now());

    const data: unknown = request.data;

    if (data === null ||
        typeof data !== "object" ||
        Array.isArray(data) ||
        Object.keys(data).length !== 1 ||
        !Object.prototype.hasOwnProperty.call(data, "deviceId")) {
      throw new HttpsError(
        "invalid-argument",
        "Invalid device status request.",
      );
    }

    const deviceId =
      (data as {deviceId: unknown}).deviceId;

    if (typeof deviceId !== "string" ||
        !/^[A-Za-z0-9_-]{43}$/.test(deviceId)) {
      throw new HttpsError(
        "invalid-argument",
        "Invalid device identifier.",
      );
    }

    const db = getFirestore();

    const rootRef = db.collection("e2eeRoots").doc(uid);

    const deviceRef = db.collection("e2eeDevices")
      .doc(uid)
      .collection("devices")
      .doc(deviceId);

    const [rootSnapshot, deviceSnapshot] =
      await Promise.all([
        rootRef.get(),
        deviceRef.get(),
      ]);

    const root = rootSnapshot.data();
    const device = deviceSnapshot.data();

    if (!rootSnapshot.exists ||
        !deviceSnapshot.exists ||
        root?.version !== 1 ||
        root.userUid !== uid ||
        typeof root.deviceId !== "string" ||
        typeof root.fingerprint !== "string" ||
        device?.version !== 1 ||
        device.userUid !== uid ||
        device.deviceId !== deviceId ||
        device.authorisedByRootDeviceId !== root.deviceId ||
        device.revokedAtMs !== null ||
        typeof device.x25519PublicKey !== "string" ||
        typeof device.ed25519PublicKey !== "string") {
      throw new HttpsError(
        "permission-denied",
        "Device registration not confirmed.",
      );
    }

    return {
      active: true,
      userUid: uid,
      deviceId,
      x25519PublicKey: device.x25519PublicKey,
      ed25519PublicKey: device.ed25519PublicKey,
      authorisedByRootDeviceId: root.deviceId,
      rootFingerprint: root.fingerprint,
    };
  },
);
