import {getFirestore, Timestamp, DocumentData} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";

const db = getFirestore();
const maxDelayMs = 9000;

/** Returns the expense day, including for records from earlier clients.
 * @param {DocumentData} data Stored expense.
 * @return {Timestamp} Date used for the historical quote.
 */
export function expenseDay(data: DocumentData): Timestamp {
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
export function isoDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

/**
 * Reads only a real provider observation, never a fallback constant.
 * @param {string} base Source currency.
 * @param {string} quote Target currency.
 * @param {Date} date Original expense date.
 * @return {Promise<FxRecord>} Observed rate and provenance.
 */
export async function fetchFxRate(base: string, quote: string, date: Date):
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
export function expenseRef(tripId: string, expenseId: string,
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
export function checkExpenseAccess(
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
