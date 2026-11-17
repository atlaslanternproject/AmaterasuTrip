import {CallableRequest, HttpsError} from "firebase-functions/v2/https";

/**
 * Returns the caller UID, or rejects callers that are not signed in
 * with a verified email.
 *
 * @param {CallableRequest} request Callable request.
 * @return {string} Authenticated and verified user UID.
 */
export function requireVerifiedUid(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (!uid || request.auth?.token.email_verified !== true) {
    throw new HttpsError("unauthenticated", "Verified user required.");
  }
  return uid;
}
