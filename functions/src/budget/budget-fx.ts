import {
  getFirestore, FieldValue, Timestamp, DocumentData,
} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {checkBudgetMembership} from "./budget-access";
import {validId} from "./budget-validation";

const db = getFirestore();
const code = /^[A-Z]{3}$/;
const maxDelayMs = 9000;

/** Returns the expense day, including for records from earlier clients.
 * @param {DocumentData} data Stored expense.
 * @return {Timestamp} Date used for the historical quote.
 */
function expenseDay(data: DocumentData): Timestamp {
  return typeof data.expenseDate === "string" ?
    Timestamp.fromDate(new Date(data.expenseDate)) : data.createdAt;
}

type FxRecord = {
  base: string;
  quote: string;
  rate: number;
  date: string;
  requestedDate: string;
  source: string;
  manual: boolean;
};

/**
 * Formats a date without time-zone-dependent day changes.
 * @param {Date} date Date to format.
 * @return {string} ISO calendar date.
 */
function isoDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

/**
 * Reads only a real provider observation, never a fallback constant.
 * @param {string} base Source currency.
 * @param {string} quote Target currency.
 * @param {Date} date Original expense date.
 * @return {Promise<FxRecord>} Observed rate and provenance.
 */
async function fetchFxRate(base: string, quote: string, date: Date):
    Promise<FxRecord> {
  const dateText = isoDate(date);
  if (dateText > isoDate(new Date())) {
    throw new HttpsError("failed-precondition", "Future FX unavailable.");
  }
  const url = new URL(
    `https://api.frankfurter.dev/v2/rate/${base}/${quote}`,
  );
  url.searchParams.set("date", dateText);
  let response: Response;
  try {
    response = await fetch(url, {signal: AbortSignal.timeout(maxDelayMs)});
  } catch {
    throw new HttpsError("unavailable", "FX provider unavailable.");
  }
  if (!response.ok) {
    throw new HttpsError("unavailable", "No observed FX rate.");
  }
  const value: unknown = await response.json();
  if (value === null || typeof value !== "object") {
    throw new HttpsError("data-loss", "Invalid FX observation.");
  }
  const data = value as Record<string, unknown>;
  const rate = data.rate;
  const observed = data.date;
  if (data.base !== base || data.quote !== quote ||
      typeof rate !== "number" || !Number.isFinite(rate) || rate <= 0 ||
      typeof observed !== "string" ||
      !/^\d{4}-\d{2}-\d{2}$/.test(observed) ||
      observed > dateText) {
    throw new HttpsError("data-loss", "Unverifiable FX observation.");
  }
  return {
    base, quote, rate, date: observed,
    requestedDate: dateText, source: "Frankfurter", manual: false,
  };
}

/**
 * Returns an expense reference inside its authorized visibility scope.
 * @param {string} tripId Trip ID.
 * @param {string} expenseId Expense ID.
 * @param {string} visibility Expense type.
 * @param {string} uid Caller UID.
 * @return {FirebaseFirestore.DocumentReference} Expense reference.
 */
function expenseRef(tripId: string, expenseId: string,
  visibility: string, uid: string) {
  if (visibility === "shared") {
    return db.collection("trips").doc(tripId)
      .collection("budgetSharedExpenses").doc(expenseId);
  }
  if (visibility === "private") {
    return db.collection("trips").doc(tripId)
      .collection("budgetPrivateOwners").doc(uid)
      .collection("expenses").doc(expenseId);
  }
  throw new HttpsError("invalid-argument", "Invalid visibility.");
}

/**
 * Verifies the user participates in the financial expense.
 * @param {DocumentData} data Expense document fields.
 * @param {string} uid Caller UID.
 * @param {string} visibility Shared or private scope.
 * @return {void} Throws if access is forbidden.
 */
function checkExpenseAccess(
  data: DocumentData, uid: string,
  visibility: string,
): void {
  if (visibility === "private") {
    if (data.createdByUid !== uid) {
      throw new HttpsError("permission-denied", "Private expense owner only.");
    }
    return;
  }
  const participants = new Set<string>([
    ...Object.keys(data.snapshot?.shares ?? {}),
    ...Object.keys(data.snapshot?.advances ?? {}),
  ]);
  if (!participants.has(uid)) {
    throw new HttpsError("permission-denied", "Not an expense participant.");
  }
}

/** Pins one authoritative historical quote to an expense, once. */
export const ensureBudgetExpenseFx = onCall(
  {region: "europe-west1", timeoutSeconds: 30},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth?.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Verified user required.");
    }
    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const visibility = request.data?.visibility;
    const ref = expenseRef(tripId, expenseId, visibility, uid);
    const tripRef = db.collection("trips").doc(tripId);
    const [trip, expense] = await Promise.all([tripRef.get(), ref.get()]);
    if (!trip.exists || !expense.exists) {
      throw new HttpsError("not-found", "Trip or expense missing.");
    }
    const tripInfo = trip.data()!;
    const active = Array.isArray(tripInfo.memberUids) ?
      tripInfo.memberUids : [];
    if (tripInfo.ownerUid !== uid && !active.includes(uid)) {
      throw new HttpsError("permission-denied", "Membership required.");
    }
    const data = expense.data()!;
    checkExpenseAccess(data, uid, visibility);
    if (data.fxHistorical) {
      return {stored: true, alreadyStored: true};
    }
    const target = trip.data()?.currency;
    const source = data.snapshot?.total?.currency;
    const createdAt = expenseDay(data);
    if (typeof source !== "string" || typeof target !== "string" ||
        !code.test(source) || !code.test(target) ||
        !(createdAt instanceof Timestamp)) {
      throw new HttpsError("failed-precondition", "FX metadata unavailable.");
    }
    if (source === target) {
      return {stored: false, sameCurrency: true};
    }
    const quote = await fetchFxRate(source, target, createdAt.toDate());
    await db.runTransaction(async (tx) => {
      await checkBudgetMembership(tx, tripId, uid);
      const current = await tx.get(ref);
      if (!current.exists) {
        throw new HttpsError("not-found", "Expense removed.");
      }
      const fresh = current.data()!;
      checkExpenseAccess(fresh, uid, visibility);
      if (fresh.fxHistorical) {
        return;
      }
      if (expenseDay(fresh)?.toMillis() !== createdAt.toMillis() ||
          fresh.snapshot?.total?.currency !== source) {
        throw new HttpsError("aborted", "Expense changed during FX lock.");
      }
      tx.update(ref, {
        fxHistorical: {...quote, lockedAt: FieldValue.serverTimestamp()},
      });
    });
    return {stored: true, alreadyStored: false};
  },
);

/** An audited, explicitly manual adjustment of display FX metadata. */
export const overrideBudgetExpenseFx = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth?.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Verified user required.");
    }
    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const visibility = request.data?.visibility;
    const rate = request.data?.rate;
    const reason = request.data?.reason;
    if (typeof rate !== "number" || !Number.isFinite(rate) ||
        rate <= 0 || rate > 1e9 || rate < 1e-9 ||
        typeof reason !== "string" || reason.trim().length < 3 ||
        reason.length > 400) {
      throw new HttpsError("invalid-argument", "Invalid manual FX correction.");
    }
    const ref = expenseRef(tripId, expenseId, visibility, uid);
    const tripRef = db.collection("trips").doc(tripId);
    const logRef = ref.collection("fxRateChanges").doc();
    await db.runTransaction(async (tx) => {
      await checkBudgetMembership(tx, tripId, uid);
      const [trip, expense] = await Promise.all([
        tx.get(tripRef), tx.get(ref),
      ]);
      if (!trip.exists || !expense.exists) {
        throw new HttpsError("not-found", "Expense unavailable.");
      }
      const data = expense.data()!;
      checkExpenseAccess(data, uid, visibility);
      if (data.createdByUid !== uid) {
        throw new HttpsError("permission-denied", "Expense author only.");
      }
      const base = data.snapshot?.total?.currency;
      const quote = trip.data()?.currency;
      const date = expenseDay(data);
      if (typeof base !== "string" || typeof quote !== "string" ||
          !code.test(base) || !code.test(quote) ||
          !(date instanceof Timestamp) || base === quote) {
        throw new HttpsError(
          "failed-precondition", "FX correction unavailable.",
        );
      }
      const previous = data.fxHistorical ?? null;
      const next = {
        base, quote, rate,
        date: isoDate(date.toDate()),
        requestedDate: isoDate(date.toDate()),
        source: "Manual", manual: true,
        lockedAt: FieldValue.serverTimestamp(),
      };
      tx.create(logRef, {
        actorUid: uid, previous, next,
        reason: reason.trim(), createdAt: FieldValue.serverTimestamp(),
      });
      tx.update(ref, {fxHistorical: next});
    });
    return {updated: true};
  },
);
