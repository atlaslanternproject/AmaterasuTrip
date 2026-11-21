import {HttpsError} from "firebase-functions/v2/https";

/**
 * Today's calendar date in UTC, as YYYY-MM-DD.
 *
 * @param {Date} now Current time.
 * @return {string} Date text.
 */
export function utcDay(now: Date): string {
  return now.toISOString().slice(0, 10);
}

/**
 * Validates the day of a declared payment (YYYY-MM-DD). Missing means
 * today. A real calendar day is required, not after tomorrow (UTC), to
 * accept every time zone, and not before 2000.
 *
 * @param {unknown} raw Value sent by the app.
 * @param {Date} now Current time.
 * @return {string} Validated day.
 */
export function validatePaidOn(raw: unknown, now: Date): string {
  if (raw === undefined || raw === null) {
    return utcDay(now);
  }
  if (typeof raw !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(raw)) {
    throw new HttpsError("invalid-argument", "Invalid payment date.");
  }
  const parsed = new Date(`${raw}T00:00:00Z`);
  if (Number.isNaN(parsed.getTime()) || utcDay(parsed) !== raw) {
    throw new HttpsError("invalid-argument", "Invalid payment date.");
  }
  const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  if (raw > utcDay(tomorrow) || raw < "2000-01-01") {
    throw new HttpsError("invalid-argument", "Invalid payment date.");
  }
  return raw;
}

/**
 * Validates an optional note (max 300 characters). Empty means none.
 *
 * @param {unknown} raw Value sent by the app.
 * @return {string | null} Trimmed note, or null.
 */
export function validateNote(raw: unknown): string | null {
  if (raw === undefined || raw === null) return null;
  if (typeof raw !== "string" || raw.length > 300) {
    throw new HttpsError("invalid-argument", "Invalid note.");
  }
  const note = raw.trim();
  return note.length === 0 ? null : note;
}

/**
 * Validates the reason of a cancellation (3 to 400 characters).
 *
 * @param {unknown} raw Value sent by the app.
 * @return {string} Trimmed reason.
 */
export function validateReason(raw: unknown): string {
  if (typeof raw !== "string" || raw.length > 400 ||
      raw.trim().length < 3) {
    throw new HttpsError("invalid-argument", "Invalid reason.");
  }
  return raw.trim();
}
