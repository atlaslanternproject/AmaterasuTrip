import {DocumentData} from "firebase-admin/firestore";

export type HistoryEvent = {
  expenseId: string;
  type: string;
  actorUid: string | null;
  counterpartUid?: string;
  minorUnits?: number;
  currency?: string;
  reason?: string;
  version?: number;
  rate?: number;
  at: number | null;
};

export type HistorySources = {
  revisions: DocumentData[];
  reimbursements: DocumentData[];
  cancellation: DocumentData | null;
  cancellationLog: DocumentData[];
  fxRateChanges: DocumentData[];
};

/**
 * Converts a Firestore timestamp (or similar) to milliseconds.
 * @param {unknown} value Stored time.
 * @return {number | null} Milliseconds, or null when unknown.
 */
function millis(value: unknown): number | null {
  if (value && typeof value === "object" &&
      typeof (value as {toMillis?: unknown}).toMillis === "function") {
    return (value as {toMillis: () => number}).toMillis();
  }
  return null;
}

/**
 * Returns the string value or null.
 * @param {unknown} value Candidate.
 * @return {string | null} Text or null.
 */
function text(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

/**
 * B8.6: builds the history of one expense from records that already
 * exist, so expenses created before this feature have a history too.
 * Pure function: no database access.
 *
 * @param {string} expenseId Expense ID.
 * @param {DocumentData} expense Expense document.
 * @param {HistorySources} sources Sub-collection records.
 * @return {HistoryEvent[]} Events, newest first.
 */
export function buildExpenseHistory(
  expenseId: string,
  expense: DocumentData,
  sources: HistorySources,
): HistoryEvent[] {
  const events: HistoryEvent[] = [];
  const currency = text(expense.snapshot?.total?.currency) ?? undefined;
  const add = (event: Omit<HistoryEvent, "expenseId">) => {
    const clean = Object.fromEntries(Object.entries(event)
      .filter(([, value]) => value !== undefined)) as typeof event;
    events.push({expenseId, ...clean});
  };

  for (const revision of sources.revisions) {
    const number = typeof revision.number === "number" ? revision.number : 0;
    add({
      type: number <= 1 ? "created" : "revised",
      actorUid: text(revision.actorUid),
      version: number || undefined,
      at: millis(revision.createdAt),
    });
  }

  for (const refund of sources.reimbursements) {
    const amount = typeof refund.minorUnits === "number" ?
      refund.minorUnits : undefined;
    const refundCurrency = text(refund.currency) ?? currency;
    if (refund.kind === "closure") {
      add({
        type: "debtClosed",
        actorUid: text(refund.decidedByUid),
        counterpartUid: text(refund.debtorUid) ?? undefined,
        minorUnits: amount, currency: refundCurrency,
        reason: text(refund.reason) ?? undefined,
        at: millis(refund.createdAt),
      });
      continue;
    }
    add({
      type: "reimbursementRequested",
      actorUid: text(refund.debtorUid),
      counterpartUid: text(refund.creditorUid) ?? undefined,
      minorUnits: amount, currency: refundCurrency,
      at: millis(refund.createdAt),
    });
    if (refund.status === "confirmed" || refund.status === "rejected") {
      add({
        type: refund.status === "confirmed" ?
          "reimbursementConfirmed" : "reimbursementRejected",
        actorUid: text(refund.decidedByUid),
        counterpartUid: text(refund.debtorUid) ?? undefined,
        minorUnits: amount, currency: refundCurrency,
        at: millis(refund.decidedAt),
      });
    }
  }

  const cancelTypes: Record<string, string> = {
    requested: "cancellationRequested",
    approved: "cancellationApproved",
    rejected: "cancellationRejected",
    cancelled: "cancelled",
  };
  if (sources.cancellationLog.length > 0) {
    for (const entry of sources.cancellationLog) {
      const type = cancelTypes[String(entry.event)];
      if (type) {
        add({
          type, actorUid: text(entry.actorUid), at: millis(entry.createdAt),
        });
      }
    }
  } else if (sources.cancellation) {
    // Records created before the cancellation log existed.
    const current = sources.cancellation;
    add({
      type: "cancellationRequested",
      actorUid: text(current.requestedByUid),
      at: millis(current.createdAt),
    });
    if (current.state === "rejected") {
      add({
        type: "cancellationRejected",
        actorUid: text(current.rejectedByUid),
        at: millis(current.updatedAt),
      });
    }
  }
  if (expense.lifecycle === "cancelled" &&
      !events.some((event) => event.type === "cancelled")) {
    add({
      type: "cancelled",
      actorUid: text(expense.cancelledByUid),
      at: millis(expense.cancelledAt) ?? millis(expense.updatedAt),
    });
  }

  for (const change of sources.fxRateChanges) {
    add({
      type: "rateChanged",
      actorUid: text(change.actorUid),
      reason: text(change.reason) ?? undefined,
      rate: typeof change.next?.rate === "number" ?
        change.next.rate : undefined,
      at: millis(change.createdAt),
    });
  }

  return sortHistory(events);
}

/**
 * Newest first; events without a time go last, order otherwise stable.
 * @param {HistoryEvent[]} events Events.
 * @return {HistoryEvent[]} Sorted copy.
 */
export function sortHistory(events: HistoryEvent[]): HistoryEvent[] {
  return events
    .map((event, index) => ({event, index}))
    .sort((a, b) => {
      const left = a.event.at ?? -Infinity;
      const right = b.event.at ?? -Infinity;
      return left === right ? a.index - b.index : right - left;
    })
    .map((item) => item.event);
}

