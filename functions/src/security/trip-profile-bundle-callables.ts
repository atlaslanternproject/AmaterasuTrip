import {createHash, createPublicKey, verify} from "node:crypto";
import {getFirestore} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {requireEncryptedTravellerProfile} from
  "./live-traveller-profile-boundary";
import {activeTripMember} from "./trip-profile-access-relay";
import {verifyTripProfileAccessProof} from
  "./trip-profile-access-proof";

type Data = Record<string, unknown>;
const invalid = (): never => {
  throw new HttpsError("permission-denied", "Invalid signed E2EE package.");
};
const record = (v: unknown): Data => {
  if (!v || typeof v !== "object" || Array.isArray(v)) return invalid();
  return v as Data;
};
const id = (v: unknown): string => {
  if (typeof v !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(v)) {
    return invalid();
  }
  return v;
};
const exact = (v: Data, keys: string[]): void => {
  if (Object.keys(v).length !== keys.length ||
      keys.some((k) => !(k in v))) invalid();
};
const bytes = (v: unknown, length: number): Buffer => {
  if (typeof v !== "string") return invalid();
  const b = Buffer.from(v, "base64");
  if (b.length !== length || b.toString("base64") !== v) return invalid();
  return b;
};
const key = (b64: unknown) => createPublicKey({
  key: Buffer.concat([
    Buffer.from("302a300506032b6570032100", "hex"), bytes(b64, 32),
  ]),
  type: "spki", format: "der",
});
const checkedSig = (b64: unknown, sig: unknown, content: unknown): void => {
  try {
    if (!verify(null, Buffer.from(JSON.stringify(content)), key(b64),
      bytes(sig, 64))) invalid();
  } catch {
    invalid();
  }
};
const canonical = (v: unknown): unknown => {
  if (Array.isArray(v)) return v.map(canonical);
  if (v !== null && typeof v === "object") {
    const m = v as Data;
    return Object.fromEntries(Object.keys(m).sort()
      .map((k) => [k, canonical(m[k])]));
  }
  return v;
};
const fingerprint = (b64: unknown): string => createHash("sha256")
  .update(bytes(b64, 32)).digest("base64url");
const caller = (request: {
  auth?: {uid: string; token: {email_verified?: boolean}};
  app?: unknown;
}): string => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign-in required.");
  }
  if (request.auth.token.email_verified !== true || !request.app) {
    throw new HttpsError("permission-denied", "Verified App Check required.");
  }
  return request.auth.uid;
};

/** Read only a pending first-root public identity for explicit OOB checking. */
export const getPendingTripAccessRoot = onCall(
  {enforceAppCheck: true}, async (request) => {
    const uid = caller(request);
    const d = record(request.data);
    const tripId = id(d.tripId);
    const requestId = id(d.requestId);
    const db = getFirestore();
    const trip = db.collection("trips").doc(tripId);
    const [t, owner, r] = await Promise.all([
      trip.get(), trip.collection("members").doc(uid).get(),
      trip.collection("profileAccessRequests").doc(requestId).get(),
    ]);
    const pending = r.data();
    if (!activeTripMember(t.data(), owner.data(), uid) ||
        pending?.profileUid !== uid || pending.status !== "pending" ||
        pending.expiresAtMs <= Date.now()) return invalid();
    const recipientUid = id(pending.recipientUid);
    const [member, root] = await Promise.all([
      trip.collection("members").doc(recipientUid).get(),
      db.collection("e2eeRoots").doc(recipientUid).get(),
    ]);
    if (!activeTripMember(t.data(), member.data(), recipientUid) ||
        root.data()?.deviceId !== pending.recipientDeviceId) return invalid();
    const k = root.data()!;
    return {recipientUid, deviceId: k.deviceId,
      x25519PublicKey: k.x25519PublicKey,
      ed25519PublicKey: k.ed25519PublicKey,
      fingerprint: fingerprint(k.x25519PublicKey)};
  },
);

/** Publish an owner-signed encrypted first grant, consuming its request. */
export const approveInitialTripProfileBundle = onCall(
  {enforceAppCheck: true}, async (request) => {
    const uid = caller(request);
    const d = record(request.data);
    const tripId = id(d.tripId);
    const requestId = id(d.requestId);
    const wire = record(d.bundle);
    if (Buffer.byteLength(JSON.stringify(wire), "utf8") > 262144) {
      return invalid();
    }
    exact(wire, ["version", "roster", "rotation"]);
    if (wire.version !== 1) return invalid();
    const roster = record(wire.roster);
    const rotation = record(wire.rotation);
    exact(roster, ["tripId", "authorityUid", "authorityDeviceId", "epoch",
      "activeDevices", "revokedMemberUids", "signature"]);
    exact(rotation, ["tripId", "profileUid", "senderDeviceId", "epoch",
      "encryptedProfile", "grants", "revokedMemberUids", "signature"]);
    if (roster.tripId !== tripId || rotation.tripId !== tripId ||
        roster.authorityUid !== uid || rotation.profileUid !== uid ||
        roster.authorityDeviceId !== rotation.senderDeviceId ||
        roster.epoch !== 2 || rotation.epoch !== 2 ||
        !Array.isArray(roster.activeDevices) ||
        !Array.isArray(rotation.grants) ||
        roster.activeDevices.length !== 2 || rotation.grants.length !== 2 ||
        !Array.isArray(roster.revokedMemberUids) ||
        !Array.isArray(rotation.revokedMemberUids) ||
        roster.revokedMemberUids.length !== 0 ||
        rotation.revokedMemberUids.length !== 0) return invalid();
    const encrypted = requireEncryptedTravellerProfile(
      rotation.encryptedProfile,
    );
    const db = getFirestore();
    const trip = db.collection("trips").doc(tripId);
    const pendingRef = trip.collection("profileAccessRequests").doc(requestId);
    const bundleRef = trip.collection("signedProfileBundles").doc(uid);
    const rootRef = db.collection("e2eeRoots").doc(uid);
    await db.runTransaction(async (tx) => {
      const [t, owner, pending, root, stored] = await Promise.all([
        tx.get(trip), tx.get(trip.collection("members").doc(uid)),
        tx.get(pendingRef), tx.get(rootRef), tx.get(bundleRef),
      ]);
      const p = pending.data();
      if (!activeTripMember(t.data(), owner.data(), uid) ||
          !p || p.profileUid !== uid || p.status !== "pending" ||
          p.expiresAtMs <= Date.now() || stored.exists ||
          root.data()?.userUid !== uid ||
          root.data()?.deviceId !== roster.authorityDeviceId) return invalid();
      const recipientUid = id(p.recipientUid);
      const [recipient, rootRecipient] = await Promise.all([
        tx.get(trip.collection("members").doc(recipientUid)),
        tx.get(db.collection("e2eeRoots").doc(recipientUid)),
      ]);
      if (!activeTripMember(t.data(), recipient.data(), recipientUid) ||
          rootRecipient.data()?.deviceId !== p.recipientDeviceId) {
        return invalid();
      }
      const trusted = [root.data()!, rootRecipient.data()!];
      const devices = (roster.activeDevices as unknown[]).map(record);
      const grants = (rotation.grants as unknown[]).map(record);
      const expectedDevices = trusted.map((r) => JSON.stringify([
        r.userUid, r.deviceId,
      ])).sort();
      const actualDevices = devices.map((r) => JSON.stringify([
        r.uid, r.deviceId,
      ])).sort();
      if (JSON.stringify(expectedDevices) !== JSON.stringify(actualDevices)) {
        return invalid();
      }
      for (const r of trusted) {
        const device = devices.find((v) =>
          v.uid === r.userUid && v.deviceId === r.deviceId);
        const grant = grants.find((v) =>
          v.recipientUid === r.userUid && v.recipientDeviceId === r.deviceId);
        if (!device || !grant ||
            device.ed25519PublicKey !== r.ed25519PublicKey ||
            device.x25519Fingerprint !== fingerprint(r.x25519PublicKey) ||
            grant.senderX25519PublicKey !== root.data()?.x25519PublicKey ||
            grant.recipientX25519PublicKey !== r.x25519PublicKey ||
            grant.tripId !== tripId || grant.profileUid !== uid ||
            grant.senderUid !== uid ||
            grant.senderDeviceId !== roster.authorityDeviceId ||
            grant.keyEpoch !== 2) return invalid();
        const wrapped = record(grant.wrappedKey);
        exact(wrapped, ["version", "algorithm", "salt", "nonce",
          "ciphertext", "mac"]);
        if (wrapped.version !== 1 ||
            wrapped.algorithm !== "HKDF-SHA256-AES256-GCM") return invalid();
        bytes(wrapped.salt, 32); bytes(wrapped.nonce, 12);
        bytes(wrapped.ciphertext, 32); bytes(wrapped.mac, 16);
        checkedSig(root.data()?.ed25519PublicKey, grant.signature, [
          "amaterasutrip", "signed-traveller-profile-key-grant", 1,
          tripId, uid, uid, r.userUid, roster.authorityDeviceId,
          r.deviceId, 2, grant.senderX25519PublicKey,
          grant.recipientX25519PublicKey, wrapped.salt, wrapped.nonce,
          wrapped.ciphertext, wrapped.mac,
        ]);
      }
      const sorted = [...devices].sort((a, b) => {
        const aa = JSON.stringify([a.uid, a.deviceId]);
        const bb = JSON.stringify([b.uid, b.deviceId]);
        return aa < bb ? -1 : aa > bb ? 1 : 0;
      });
      if (JSON.stringify(devices) !== JSON.stringify(sorted)) return invalid();
      checkedSig(root.data()?.ed25519PublicKey, roster.signature, [
        "amaterasutrip", "signed-trip-device-roster", 1, tripId, uid,
        roster.authorityDeviceId, 2,
        devices.map((v) => [v.uid, v.deviceId, v.x25519Fingerprint,
          v.ed25519PublicKey]), [],
      ]);
      checkedSig(root.data()?.ed25519PublicKey, rotation.signature, [
        "amaterasutrip", "signed-profile-key-rotation", 1, tripId, uid,
        roster.authorityDeviceId, 2, JSON.stringify(canonical(encrypted)),
        [], grants.map((g) => {
          const w = record(g.wrappedKey);
          const signBytes = Buffer.from(JSON.stringify([
            "amaterasutrip", "signed-traveller-profile-key-grant", 1,
            tripId, uid, uid, g.recipientUid, roster.authorityDeviceId,
            g.recipientDeviceId, 2, g.senderX25519PublicKey,
            g.recipientX25519PublicKey, w.salt, w.nonce,
            w.ciphertext, w.mac,
          ]));
          return [signBytes.toString("base64"), g.signature];
        }),
      ]);
      tx.create(bundleRef, {version: 1, tripId, profileUid: uid,
        recipientUid, recipientDeviceId: p.recipientDeviceId,
        epoch: 2, bundle: wire, publishedAtMs: Date.now()});
      tx.update(pendingRef, {status: "approved", approvedAtMs: Date.now()});
      tx.update(trip.collection("members").doc(uid), {
        travellerProfileCompleted: true, travellerProfile: encrypted,
      });
    });
    return {approved: true, epoch: 2};
  },
);

/** Read only a grant for the authenticated, signed first device. */
export const getApprovedTripProfileBundle = onCall(
  {enforceAppCheck: true}, async (request) => {
    const uid = caller(request);
    const d = record(request.data);
    const tripId = id(d.tripId);
    const profileUid = id(d.profileUid);
    const deviceId = id(d.deviceId);
    const db = getFirestore();
    const trip = db.collection("trips").doc(tripId);
    const root = db.collection("e2eeRoots").doc(uid);
    const now = Date.now();
    return db.runTransaction(async (tx) => {
      const [t, member, owner, r, stored] = await Promise.all([
        tx.get(trip), tx.get(trip.collection("members").doc(uid)),
        tx.get(trip.collection("members").doc(profileUid)),
        tx.get(root), tx.get(trip.collection("signedProfileBundles")
          .doc(profileUid)),
      ]);
      const b = stored.data();
      if (!activeTripMember(t.data(), member.data(), uid) ||
          !activeTripMember(t.data(), owner.data(), profileUid) ||
          !b ||
          (uid !== profileUid && (b.recipientUid !== uid ||
            b.recipientDeviceId !== deviceId)) ||
          r.data()?.deviceId !== deviceId) return invalid();
      const proof = verifyTripProfileAccessProof(d.proof, r.data(), {
        uid, tripId, profileUid, deviceId,
      }, now);
      const nonceId = createHash("sha256")
        .update(JSON.stringify(["get-bundle", uid, proof.nonce]))
        .digest("hex");
      const nonce = trip.collection("profileAccessRequestNonces").doc(nonceId);
      const existing = await tx.get(nonce);
      if (existing.exists) return invalid();
      tx.create(nonce, {uid, consumedAtMs: now});
      return {bundle: b.bundle};
    });
  },
);
