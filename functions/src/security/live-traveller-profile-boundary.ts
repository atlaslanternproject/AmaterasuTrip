import {HttpsError} from "firebase-functions/v2/https";
import {parseProtectedTravellerProfile} from "./traveller-profile-transport";
import type {ProtectedTravellerProfileTransport} from
  "./traveller-profile-transport";

/**
 * Deployed callable boundary: reject legacy plaintext and any extra fields.
 * Neither accepted profiles nor failures are written to application logs.
 * This is shape validation only; membership and key trust need separate checks.
 */
export function requireEncryptedTravellerProfile(
  raw: unknown,
): ProtectedTravellerProfileTransport {
  try {
    return parseProtectedTravellerProfile(raw);
  } catch (_) {
    throw new HttpsError(
      "invalid-argument",
      "An encrypted traveller profile is required.",
    );
  }
}

/**
 * Legacy Firestore records may contain plaintext. They must NEVER be
 * projected to a caller. Returning null does not erase historical data.
 */
export function projectEncryptedTravellerProfile(
  raw: unknown,
): ProtectedTravellerProfileTransport | null {
  try {
    return parseProtectedTravellerProfile(raw);
  } catch (_) {
    return null;
  }
}
