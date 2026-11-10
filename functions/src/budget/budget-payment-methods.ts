import {HttpsError} from "firebase-functions/v2/https";
import {Snapshot, validId} from "./budget-validation";

export type PaymentMethod = {
  payerUid: string;
  method: string;
  minorUnits: number;
  otherLabel?: string;
  accountCurrency?: string;
  accountDebitMinor?: number;
};

const methods = new Set([
  "cash",
  "card",
  "bankTransfer",
  "paypal",
  "satispay",
  "other",
]);

/**
 * Validates optional payment details against recorded advances.
 * Legacy expenses may omit this field.
 *
 * @param {unknown} raw Optional payment method declarations.
 * @param {Snapshot} snapshot Validated financial snapshot.
 * @return {PaymentMethod[]|null} Validated details or legacy null.
 */
export function validatePaymentMethods(
  raw: unknown,
  snapshot: Snapshot,
): PaymentMethod[] | null {
  if (raw === undefined) return null;

  if (!Array.isArray(raw) || raw.length > 100) {
    throw new HttpsError(
      "invalid-argument", "Invalid payment methods.",
    );
  }

  const result: PaymentMethod[] = [];
  const totals = new Map<string, number>();

  for (const item of raw) {
    if (item === null || typeof item !== "object" ||
        Array.isArray(item)) {
      throw new HttpsError(
        "invalid-argument", "Invalid payment entry.",
      );
    }

    const data = item as Record<string, unknown>;
    const keys = Object.keys(data);
    const allowed = [
      "payerUid", "method", "minorUnits", "otherLabel",
      "accountCurrency", "accountDebitMinor",
    ];

    if (keys.some((key) => !allowed.includes(key)) ||
        !keys.includes("payerUid") ||
        !keys.includes("method") ||
        !keys.includes("minorUnits")) {
      throw new HttpsError(
        "invalid-argument", "Invalid payment fields.",
      );
    }

    const payerUid = validId(data.payerUid);
    const method = data.method;
    const minorUnits = data.minorUnits;
    const otherLabel = data.otherLabel;

    if (typeof method !== "string" ||
        !methods.has(method) ||
        typeof minorUnits !== "number" ||
        !Number.isSafeInteger(minorUnits) ||
        minorUnits <= 0) {
      throw new HttpsError(
        "invalid-argument", "Invalid payment value.",
      );
    }

    if (method === "other") {
      if (typeof otherLabel !== "string" ||
          otherLabel.trim().length === 0 ||
          otherLabel.trim().length > 40) {
        throw new HttpsError(
          "invalid-argument", "Other method needs a label.",
        );
      }
    } else if (otherLabel !== undefined) {
      throw new HttpsError(
        "invalid-argument", "Unexpected payment label.",
      );
    }

    const account = data.accountCurrency;
    const debit = data.accountDebitMinor;
    if ((account !== undefined && (typeof account !== "string" ||
        !/^[A-Z]{3}$/.test(account))) || (debit !== undefined &&
        (account === undefined || typeof debit !== "number" ||
        !Number.isSafeInteger(debit) || debit <= 0))) {
      throw new HttpsError("invalid-argument", "Invalid account debit.");
    }
    const previous = totals.get(payerUid) ?? 0;
    const updated = previous + minorUnits;

    if (!Number.isSafeInteger(updated)) {
      throw new HttpsError(
        "invalid-argument", "Payment amount overflow.",
      );
    }

    totals.set(payerUid, updated);

    result.push({
      payerUid,
      ...(typeof account === "string" ? {accountCurrency: account} : {}),
      ...(typeof debit === "number" ? {accountDebitMinor: debit} : {}),
      method,
      minorUnits,
      ...(method === "other" ?
        {otherLabel: (otherLabel as string).trim()} : {}),
    });
  }

  const payers = new Set([
    ...totals.keys(),
    ...Object.keys(snapshot.advances),
  ]);

  for (const uid of payers) {
    const declared = totals.get(uid) ?? 0;
    const advanced = snapshot.advances[uid]?.minorUnits ?? 0;

    if (declared !== advanced) {
      throw new HttpsError(
        "invalid-argument",
        "Payment methods do not match advances.",
      );
    }
  }

  return result;
}
