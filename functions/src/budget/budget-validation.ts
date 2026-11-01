import {HttpsError} from "firebase-functions/v2/https";

export type Money = {
  currency: string;
  minorUnits: number;
};

export type Snapshot = {
  total: Money;
  status: "planned" | "outstanding" | "paid";
  shares: Record<string, Money>;
  advances: Record<string, Money>;
};

const maxSafe = Number.MAX_SAFE_INTEGER;
const currencyPattern = /^[A-Z]{3}$/;
const uidPattern = /^[A-Za-z0-9_-]{1,128}$/;

/**
 * Validates a Firestore document identifier.
 *
 * @param {unknown} value Candidate identifier.
 * @return {string} Validated identifier.
 */
export function validId(value: unknown): string {
  if (typeof value !== "string" ||
      !uidPattern.test(value)) {
    throw new HttpsError("invalid-argument", "Invalid identifier.");
  }
  return value;
}

/**
 * Requires a non-array object.
 *
 * @param {unknown} value Candidate object.
 * @return {Record<string, unknown>} Validated object.
 */
function objectValue(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" ||
      Array.isArray(value)) {
    throw new HttpsError("invalid-argument", "Object required.");
  }
  return value as Record<string, unknown>;
}

/**
 * Checks that an object contains exactly the expected fields.
 *
 * @param {Record<string, unknown>} value Object to validate.
 * @param {string[]} expected Expected field names.
 * @return {void} Throws when fields differ.
 */
function exactKeys(
  value: Record<string, unknown>,
  expected: string[],
): void {
  const actual = Object.keys(value);
  if (actual.length !== expected.length ||
      actual.some((key) => !expected.includes(key))) {
    throw new HttpsError("invalid-argument", "Unexpected fields.");
  }
}

/**
 * Validates an exact monetary amount.
 *
 * @param {unknown} value Candidate amount.
 * @param {string} currency Optional required currency.
 * @return {Money} Validated monetary amount.
 */
function money(value: unknown, currency?: string): Money {
  const data = objectValue(value);
  exactKeys(data, ["currency", "minorUnits"]);
  if (typeof data.currency !== "string" ||
      !currencyPattern.test(data.currency) ||
      (currency && data.currency !== currency) ||
      typeof data.minorUnits !== "number" ||
      !Number.isSafeInteger(data.minorUnits) ||
      data.minorUnits < 0 ||
      data.minorUnits > maxSafe) {
    throw new HttpsError("invalid-argument", "Invalid money.");
  }
  return {
    currency: data.currency,
    minorUnits: data.minorUnits,
  };
}

/**
 * Validates traveler amounts in a single currency.
 *
 * @param {unknown} value Candidate traveler amounts.
 * @param {string} currency Required currency.
 * @return {Record<string, Money>} Validated amounts.
 */
function amounts(
  value: unknown,
  currency: string,
): Record<string, Money> {
  const input = objectValue(value);
  if (Object.keys(input).length > 100) {
    throw new HttpsError("invalid-argument", "Too many travelers.");
  }
  const result: Record<string, Money> = {};
  for (const [uid, amount] of Object.entries(input)) {
    validId(uid);
    result[uid] = money(amount, currency);
  }
  return result;
}

/**
 * Validates expense totals, shares, advances and payment status.
 *
 * @param {unknown} value Candidate financial snapshot.
 * @return {Snapshot} Validated financial snapshot.
 */
export function validateSnapshot(value: unknown): Snapshot {
  const data = objectValue(value);
  exactKeys(data, ["total", "status", "shares", "advances"]);
  const total = money(data.total);
  const currency = total.currency;
  if (total.minorUnits <= 0) {
    throw new HttpsError("invalid-argument", "Positive total required.");
  }

  const status = data.status;
  if (status !== "planned" &&
      status !== "outstanding" &&
      status !== "paid") {
    throw new HttpsError("invalid-argument", "Invalid status.");
  }

  const shares = amounts(data.shares, currency);
  const advances = amounts(data.advances, currency);

  if (Object.keys(shares).length === 0) {
    throw new HttpsError("invalid-argument", "Shares required.");
  }

  const sum = (values: Record<string, Money>) =>
    Object.values(values).reduce(
      (current, next) => current + next.minorUnits,
      0,
    );

  const shareTotal = sum(shares);
  const paidTotal = sum(advances);

  if (!Number.isSafeInteger(shareTotal) ||
      !Number.isSafeInteger(paidTotal) ||
      shareTotal !== total.minorUnits ||
      paidTotal > total.minorUnits) {
    throw new HttpsError("invalid-argument", "Unbalanced expense.");
  }

  if ((status === "planned" && paidTotal !== 0) ||
      (status === "paid" && paidTotal !== total.minorUnits) ||
      (status === "outstanding" &&
       paidTotal >= total.minorUnits)) {
    throw new HttpsError("invalid-argument", "Inconsistent status.");
  }

  return {total, status, shares, advances};
}

/**
 * Calculates one debtor-creditor obligation within an expense.
 *
 * @param {Snapshot} snapshot Financial expense snapshot.
 * @param {string} debtorUid Debtor identifier.
 * @param {string} creditorUid Creditor identifier.
 * @return {number} Original debt in minor currency units.
 */
export function debtAmount(
  snapshot: Snapshot,
  debtorUid: string,
  creditorUid: string,
): number {
  if (snapshot.status !== "paid" ||
      debtorUid === creditorUid) {
    return 0;
  }

  const uids = [...new Set([
    ...Object.keys(snapshot.shares),
    ...Object.keys(snapshot.advances),
  ])].sort();

  const debtors = new Map<string, number>();
  const creditors = new Map<string, number>();

  for (const uid of uids) {
    const share = snapshot.shares[uid]?.minorUnits ?? 0;
    const advance = snapshot.advances[uid]?.minorUnits ?? 0;
    const delta = advance - share;
    if (delta < 0) debtors.set(uid, -delta);
    if (delta > 0) creditors.set(uid, delta);
  }

  let result = 0;

  for (const debtor of uids) {
    let remaining = debtors.get(debtor) ?? 0;
    for (const creditor of uids) {
      const available = creditors.get(creditor) ?? 0;
      const assigned = Math.min(remaining, available);
      if (debtor === debtorUid && creditor === creditorUid) {
        result += assigned;
      }
      remaining -= assigned;
      creditors.set(creditor, available - assigned);
    }
  }

  return result;
}
