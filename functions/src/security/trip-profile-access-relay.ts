import {createHash} from "node:crypto";
import {getFirestore} from "firebase-admin/firestore";
import {verifyTripProfileAccessProof} from
  "./trip-profile-access-proof";
import {HttpsError, onCall} from "firebase-functions/v2/https";

/**
 * Check active membership against both authoritative trip membership
 * and its member document.
 *
 * @param {Object|undefined} trip Trip document.
 * @param {Object|undefined} member Member document.
 * @param {string} uid Expected account UID.
 * @return {boolean} Whether membership is active.
 */
export function activeTripMember(
  trip: Record<string, unknown> | undefined,
  member: Record<string, unknown> | undefined,
  uid: string,
): boolean {
  return Boolean(
    trip && member && member.uid === uid &&
    (trip.ownerUid === uid ||
      (Array.isArray(trip.memberUids) &&
        trip.memberUids.includes(uid))),
  );
}

/**
 * Validate a Firestore document identifier.
 *
 * @param {unknown} value Untrusted identifier.
 * @return {string} Valid identifier.
 */
function safeId(value: unknown): string {
  if (typeof value !== "string" ||
      !/^[A-Za-z0-9_-]{1,128}$/.test(value)) {
    throw new HttpsError("invalid-argument", "Invalid identifier.");
  }
  return value;
}

/**
 * Require authenticated, verified access with App Check.
 *
 * @param {Object} request Callable context.
 * @return {string} Firebase account UID.
 */
function caller(request: {
  auth?: {
    uid: string;
    token: {email_verified?: boolean};
  };
  app?: unknown;
}): string {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign-in required.");
  }
  if (request.auth.token.email_verified !== true || !request.app) {
    throw new HttpsError(
      "permission-denied",
      "Verified sign-in and App Check required.",
    );
  }
  return request.auth.uid;
}

/**
 * Validate a request object.
 *
 * @param {unknown} value Callable request data.
 * @return {Object} Valid JSON object.
 */
function requestData(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" ||
      Array.isArray(value)) {
    throw new HttpsError("invalid-argument", "Invalid request.");
  }
  return value as Record<string, unknown>;
}

/** Submit an untrusted access request. Never deliver a key here. */
export const requestTripProfileAccess = onCall(
  {enforceAppCheck: true},
  async (request) => {
    const uid = caller(request);
    const data = requestData(request.data);
    const tripId = safeId(data.tripId);
    const profileUid = safeId(data.profileUid);
    const deviceId = safeId(data.recipientDeviceId);

    if (uid === profileUid) {
      throw new HttpsError(
        "invalid-argument", "Cannot request your own profile.",
      );
    }

    const db = getFirestore();
    const trip = db.collection("trips").doc(tripId);
    const root = db.collection("e2eeRoots").doc(uid);

    const rateId = createHash("sha256")
      .update(JSON.stringify([uid, profileUid]))
      .digest("hex");

    const rate = trip.collection("profileAccessRate").doc(rateId);
    const pending = trip.collection("profileAccessRequests").doc();
    const now = Date.now();

    await db.runTransaction(async (tx) => {
      const [tripDoc, owner, recipient, rootDoc, rateDoc] =
        await Promise.all([
          tx.get(trip),
          tx.get(trip.collection("members").doc(profileUid)),
          tx.get(trip.collection("members").doc(uid)),
          tx.get(root),
          tx.get(rate),
        ]);

      if (!activeTripMember(
        tripDoc.data(), owner.data(), profileUid,
      ) ||
          !activeTripMember(
            tripDoc.data(), recipient.data(), uid,
          ) ||
          !rootDoc.exists ||
          rootDoc.data()?.deviceId !== deviceId) {
        throw new HttpsError(
          "permission-denied",
          "Active membership and first device required.",
        );
      }

      const checked = verifyTripProfileAccessProof(
        data.proof,
        rootDoc.data(),
        {uid, tripId, profileUid, deviceId},
        now,
      );

      const nonceId = createHash("sha256")
        .update(JSON.stringify([uid, checked.nonce]))
        .digest("hex");

      const nonceRef = trip.collection(
        "profileAccessRequestNonces",
      ).doc(nonceId);

      const nonceDoc = await tx.get(nonceRef);

      if (nonceDoc.exists) {
        throw new HttpsError(
          "already-exists",
          "Signed device request already used.",
        );
      }

      const previous = rateDoc.data()?.requestedAtMs;
      if (typeof previous === "number" &&
          now - previous < 60000) {
        throw new HttpsError(
          "resource-exhausted", "Request rate limit reached.",
        );
      }

      // All transaction reads are completed before the writes.
      tx.create(nonceRef, {
        uid,
        createdAtMs: now,
        expiresAtMs: now + 86400000,
      });
      tx.set(rate, {requestedAtMs: now});
      tx.create(pending, {
        version: 1,
        tripId,
        profileUid,
        recipientUid: uid,
        recipientDeviceId: deviceId,
        status: "pending",
        createdAtMs: now,
        expiresAtMs: now + 600000,
      });
    });

    return {requestId: pending.id};
  },
);

/** List only pending requests addressed to the profile owner. */
export const listMyTripProfileAccessRequests = onCall(
  {enforceAppCheck: true},
  async (request) => {
    const uid = caller(request);
    const data = requestData(request.data);
    const tripId = safeId(data.tripId);

    const db = getFirestore();
    const trip = db.collection("trips").doc(tripId);

    const [tripDoc, memberDoc] = await Promise.all([
      trip.get(),
      trip.collection("members").doc(uid).get(),
    ]);

    const tripData = tripDoc.data();

    if (!activeTripMember(tripData, memberDoc.data(), uid)) {
      throw new HttpsError(
        "permission-denied", "Membership required.",
      );
    }

    const result = await trip.collection("profileAccessRequests")
      .where("profileUid", "==", uid)
      .limit(100)
      .get();

    const now = Date.now();
    const items = result.docs
      .filter((doc) => {
        const item = doc.data();
        const other = item.recipientUid;
        return item.status === "pending" &&
          item.expiresAtMs > now &&
          typeof other === "string" &&
          (tripData?.ownerUid === other ||
            (Array.isArray(tripData?.memberUids) &&
              tripData.memberUids.includes(other)));
      })
      .map((doc) => ({
        requestId: doc.id,
        recipientUid: doc.data().recipientUid,
        expiresAtMs: doc.data().expiresAtMs,
      }));

    return {requests: items};
  },
);

/** Let the profile owner decline a pending request. */
export const declineTripProfileAccessRequest = onCall(
  {enforceAppCheck: true},
  async (request) => {
    const uid = caller(request);
    const data = requestData(request.data);
    const tripId = safeId(data.tripId);
    const requestId = safeId(data.requestId);

    const db = getFirestore();
    const trip = db.collection("trips").doc(tripId);
    const ref = trip.collection("profileAccessRequests").doc(requestId);

    await db.runTransaction(async (tx) => {
      const [tripDoc, memberDoc, pending] =
        await Promise.all([
          tx.get(trip),
          tx.get(trip.collection("members").doc(uid)),
          tx.get(ref),
        ]);

      if (!activeTripMember(
        tripDoc.data(), memberDoc.data(), uid,
      ) ||
          pending.data()?.profileUid !== uid ||
          pending.data()?.status !== "pending") {
        throw new HttpsError(
          "permission-denied",
          "Request cannot be declined.",
        );
      }

      tx.update(ref, {
        status: "declined",
        declinedAtMs: Date.now(),
      });
    });

    return {declined: true};
  },
);
