import {
  getFirestore, FieldValue, Transaction, DocumentReference,
} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {checkBudgetMembership} from "./budget-access";
import {validId} from "./budget-validation";

/**
 * B8.6: appends one event to the cancellation log of an expense.
 * @param {Transaction} tx Firestore transaction.
 * @param {DocumentReference} expenseRef Expense reference.
 * @param {string} event requested, approved, rejected or cancelled.
 * @param {string} uid Acting traveler.
 * @return {void}
 */
function logCancellation(
  tx: Transaction, expenseRef: DocumentReference, event: string, uid: string,
): void {
  tx.create(expenseRef.collection("cancellationLog").doc(), {
    event, actorUid: uid, createdAt: FieldValue.serverTimestamp(),
  });
}


const db = getFirestore();

/** Creates a cancellation proposal; no financial document is deleted. */
export const requestBudgetCancellation = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth?.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Verified user required.");
    }
    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const expenseRef = db.collection("trips").doc(tripId)
      .collection("budgetSharedExpenses").doc(expenseId);
    const cancelRef = expenseRef.collection("cancellation").doc("current");
    await db.runTransaction(async (tx) => {
      const active = await checkBudgetMembership(tx, tripId, uid);
      const expense = await tx.get(expenseRef);
      const previous = await tx.get(cancelRef);
      if (!expense.exists) {
        throw new HttpsError("not-found", "Expense missing.");
      }
      const data = expense.data()!;
      if (data.lifecycle === "cancelled") {
        throw new HttpsError("failed-precondition", "Already cancelled.");
      }
      if (previous.exists && previous.data()?.state === "pending") {
        throw new HttpsError("failed-precondition", "Cancellation pending.");
      }
      const snapshot = data.snapshot;
      const required: string[] = [...new Set<string>([
        ...Object.keys(snapshot?.shares ?? {}),
        ...Object.keys(snapshot?.advances ?? {}),
        data.createdByUid,
      ])].sort();
      if (!required.includes(uid) ||
          required.some((id) => !active.includes(id))) {
        throw new HttpsError(
          "permission-denied", "Not a participating traveler.");
      }
      const refunds = await tx.get(expenseRef.collection("reimbursements"));
      if (!refunds.empty) {
        throw new HttpsError(
          "failed-precondition", "Reimbursements require manual correction.",
        );
      }
      const proposals = await tx.get(expenseRef.collection("proposals")
        .where("state", "==", "pending"));
      if (!proposals.empty) {
        throw new HttpsError(
          "failed-precondition", "Revision currently pending.",
        );
      }
      tx.set(cancelRef, {
        state: required.length === 1 ? "approved" : "pending",
        baseVersion: data.version,
        requiredUids: required, approvedUids: [uid],
        requestedByUid: uid, createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      // B8.6: append-only log, "current" is replaced by a new request.
      logCancellation(tx, expenseRef, "requested", uid);
      if (required.length === 1) {
        logCancellation(tx, expenseRef, "cancelled", uid);
        tx.update(expenseRef, {
          lifecycle: "cancelled", cancelledAt: FieldValue.serverTimestamp(),
          cancelledByUid: uid, updatedAt: FieldValue.serverTimestamp(),
        });
      }
    });
    return {requested: true};
  },
);

/** Records one affected traveler's decision; unanimity cancels expense. */
export const decideBudgetCancellation = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth?.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Verified user required.");
    }
    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const approved = request.data?.approved;
    if (typeof approved !== "boolean") {
      throw new HttpsError(
        "invalid-argument", "Decision required.",
      );
    }
    const expenseRef = db.collection("trips").doc(tripId)
      .collection("budgetSharedExpenses").doc(expenseId);
    const cancelRef = expenseRef.collection("cancellation").doc("current");
    await db.runTransaction(async (tx) => {
      const active = await checkBudgetMembership(tx, tripId, uid);
      const expense = await tx.get(expenseRef);
      const cancellation = await tx.get(cancelRef);
      if (!expense.exists || !cancellation.exists) {
        throw new HttpsError(
          "not-found", "Cancellation not found.",
        );
      }
      const data = expense.data()!;
      const pending = cancellation.data()!;
      if (pending.state !== "pending" ||
          data.lifecycle === "cancelled" ||
          pending.baseVersion !== data.version) {
        throw new HttpsError(
          "failed-precondition", "Cancellation not current.");
      }
      const required = pending.requiredUids as string[];
      const previous = pending.approvedUids as string[];
      if (required.some((id) => !active.includes(id))) {
        throw new HttpsError(
          "failed-precondition", "Participant left trip.",
        );
      }
      if (!required.includes(uid) || previous.includes(uid)) {
        throw new HttpsError(
          "permission-denied", "Decision not permitted.",
        );
      }
      if (!approved) {
        tx.update(cancelRef, {
          state: "rejected", rejectedByUid: uid,
          updatedAt: FieldValue.serverTimestamp(),
        });
        logCancellation(tx, expenseRef, "rejected", uid);
        return;
      }
      const next = [...previous, uid];
      if (next.length === required.length) {
        const refunds = await tx.get(expenseRef.collection("reimbursements"));
        if (!refunds.empty) {
          throw new HttpsError(
            "failed-precondition", "Expense now has reimbursements.",
          );
        }
        tx.update(expenseRef, {
          lifecycle: "cancelled", cancelledByUid: uid,
          cancelledAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        tx.update(cancelRef, {
          state: "approved", approvedUids: next,
          updatedAt: FieldValue.serverTimestamp(),
        });
        logCancellation(tx, expenseRef, "approved", uid);
        logCancellation(tx, expenseRef, "cancelled", uid);
      } else {
        tx.update(cancelRef, {
          approvedUids: next, updatedAt: FieldValue.serverTimestamp(),
        });
        logCancellation(tx, expenseRef, "approved", uid);
      }
    });
    return {decided: true};
  },
);
