import {getFirestore} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {checkBudgetMembership} from "./budget-access";
import {validId} from "./budget-validation";

const db = getFirestore();
const maxNameLength = 80;

/**
 * Display name with the same rule as the app traveler list:
 * username first, otherwise "first last". Only the name is copied,
 * never other profile data.
 *
 * @param {unknown} profile Global traveler profile.
 * @return {string | null} Display name, or null when unknown.
 */
export function displayName(profile: unknown): string | null {
  if (profile === null || typeof profile !== "object") return null;
  const data = profile as Record<string, unknown>;
  const text = (value: unknown) =>
    typeof value === "string" ? value.trim() : "";
  const username = text(data.username);
  const full = `${text(data.firstName)} ${text(data.lastName)}`.trim();
  const name = username || full;
  return name ? name.slice(0, maxNameLength) : null;
}

/**
 * Reads display names of the given travelers from their global profiles.
 *
 * @param {Iterable<string>} uids Traveler identifiers.
 * @return {Promise<Record<string, string>>} Known names by UID.
 */
export async function loadDisplayNames(
  uids: Iterable<string>,
): Promise<Record<string, string>> {
  const unique = [...new Set(uids)].filter((uid) => uid.length > 0);
  if (unique.length === 0) return {};
  const docs = await db.getAll(
    ...unique.map((uid) => db.collection("viaggiatori").doc(uid)),
  );
  const result: Record<string, string> = {};
  for (const doc of docs) {
    const name = doc.exists ? displayName(doc.data()) : null;
    if (name) result[doc.id] = name;
  }
  return result;
}

/**
 * B8.6: keeps traveler names inside shared financial records, so that a
 * traveler who leaves the trip is still shown by name. Fills missing names
 * and refreshes names of active members; names of former members are
 * kept as recorded.
 */
export const syncBudgetParticipantNames = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth?.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Verified user required.");
    }
    const tripId = validId(request.data?.tripId);
    const active = await db.runTransaction((tx) =>
      checkBudgetMembership(tx, tripId, uid));

    const expenses = await db.collection("trips").doc(tripId)
      .collection("budgetSharedExpenses")
      .where("participantUids", "array-contains", uid)
      .get();

    const everyone = new Set<string>();
    for (const doc of expenses.docs) {
      for (const id of doc.get("participantUids") ?? []) {
        if (typeof id === "string") everyone.add(id);
      }
    }
    const names = await loadDisplayNames(everyone);

    let updated = 0;
    const batch = db.batch();
    for (const doc of expenses.docs) {
      // One batch holds at most 500 writes; the next call continues.
      if (updated >= 450) break;
      const stored = (doc.get("participantNames") ?? {}) as
        Record<string, unknown>;
      const next: Record<string, string> = {};
      for (const [id, value] of Object.entries(stored)) {
        if (typeof value === "string") next[id] = value;
      }
      for (const id of doc.get("participantUids") ?? []) {
        const name = names[id];
        if (!name) continue;
        if (next[id] === undefined || active.includes(id)) next[id] = name;
      }
      const changed = Object.keys(next).length !==
          Object.keys(stored).length ||
        Object.entries(next).some(([id, name]) => stored[id] !== name);
      if (changed) {
        batch.update(doc.ref, {participantNames: next});
        updated++;
      }
    }
    if (updated > 0) await batch.commit();
    return {updated};
  },
);
