import type {Snapshot} from "./budget-validation";

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

/**
 * Reimbursement statuses that reduce an original debt: confirmed
 * reimbursements and B8.6 closures of a former member's debt.
 */
export const settledStatuses: readonly string[] = ["confirmed", "writtenOff"];

/**
 * Sums reimbursement records of one debt pair with the given statuses.
 * Mirrors BudgetSnapshotDebts.sumFor in the Flutter app.
 *
 * @param {Iterable<Record<string, unknown>>} items Reimbursement records.
 * @param {string} debtorUid Debtor identifier.
 * @param {string} creditorUid Creditor identifier.
 * @param {string[]} statuses Statuses to include.
 * @return {number} Sum in minor currency units.
 */
export function sumReimbursements(
  items: Iterable<Record<string, unknown>>,
  debtorUid: string,
  creditorUid: string,
  statuses: readonly string[],
): number {
  let sum = 0;
  for (const item of items) {
    const amount = item.minorUnits;
    if (item.debtorUid === debtorUid &&
        item.creditorUid === creditorUid &&
        typeof item.status === "string" &&
        statuses.includes(item.status) &&
        typeof amount === "number" &&
        Number.isSafeInteger(amount) && amount > 0) {
      sum += amount;
    }
  }
  return sum;
}
