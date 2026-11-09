import {HttpsError} from "firebase-functions/v2/https";
import {validId} from "./budget-validation";

export type ReimbursementMethod = {
  payerUid: string;
  method: string;
  minorUnits: number;
  otherLabel?: string;
};

const allowed = new Set([
  "cash", "card", "bankTransfer", "paypal", "satispay", "other",
]);

/**
 * Validates the declared reimbursement methods.
 * Missing methods remain supported for older clients.
 *
 * @param {unknown} raw Submitted methods.
 * @param {string} debtorUid Authenticated debtor.
 * @param {number} amount Declared reimbursement total.
 * @return {ReimbursementMethod[]|null} Validated methods.
 */
export function validateReimbursementMethods(
  raw: unknown,
  debtorUid: string,
  amount: number,
): ReimbursementMethod[] | null {
  if (raw === undefined) return null;

  if (!Array.isArray(raw) || raw.length < 1 || raw.length > 20) {
    throw new HttpsError("invalid-argument", "Invalid payment methods.");
  }

  const result: ReimbursementMethod[] = [];
  let total = 0;

  for (const item of raw) {
    if (item === null || typeof item !== "object" ||
        Array.isArray(item)) {
      throw new HttpsError("invalid-argument", "Invalid payment entry.");
    }

    const data = item as Record<string, unknown>;
    const keys = Object.keys(data);
    const fields = ["payerUid", "method", "minorUnits", "otherLabel"];

    if (keys.some((key) => !fields.includes(key)) ||
        !keys.includes("payerUid") ||
        !keys.includes("method") ||
        !keys.includes("minorUnits")) {
      throw new HttpsError("invalid-argument", "Invalid payment fields.");
    }

    const payerUid = validId(data.payerUid);
    const method = data.method;
    const minorUnits = data.minorUnits;
    const label = data.otherLabel;

    if (payerUid !== debtorUid ||
        typeof method !== "string" || !allowed.has(method) ||
        typeof minorUnits !== "number" ||
        !Number.isSafeInteger(minorUnits) || minorUnits <= 0) {
      throw new HttpsError("invalid-argument", "Invalid payment value.");
    }

    if (method === "other") {
      if (typeof label !== "string" ||
          label.trim().length < 1 || label.trim().length > 40) {
        throw new HttpsError("invalid-argument", "Invalid other method.");
      }
    } else if (label !== undefined) {
      throw new HttpsError("invalid-argument", "Unexpected method label.");
    }

    total += minorUnits;
    if (!Number.isSafeInteger(total) || total > amount) {
      throw new HttpsError("invalid-argument", "Invalid payment total.");
    }

    result.push({
      payerUid,
      method,
      minorUnits,
      ...(method === "other" ?
        {otherLabel: (label as string).trim()} : {}),
    });
  }

  if (total !== amount) {
    throw new HttpsError("invalid-argument", "Payment total mismatch.");
  }

  return result;
}
