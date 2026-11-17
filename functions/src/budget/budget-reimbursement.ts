import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {checkBudgetMembership} from "./budget-access";
import {
  validId, debtAmount, Snapshot, settledStatuses, sumReimbursements,
} from "./budget-validation";

import {validateReimbursementMethods} from "./budget-reimbursement-methods";

const db = getFirestore();

/**
 * Builds Firestore references for an expense and reimbursement.
 *
 * @param {string} tripId Trip identifier.
 * @param {string} expenseId Expense identifier.
 * @param {string} refundId Reimbursement identifier.
 * @return {object} Expense and reimbursement references.
 */
function refs(tripId: string, expenseId: string, refundId: string) {
  const expense = db.collection("trips").doc(tripId)
    .collection("budgetSharedExpenses").doc(expenseId);
  return {
    expense,
    refund: expense.collection("reimbursements").doc(refundId),
  };
}

export const requestBudgetReimbursement = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth?.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Verified user required.");
    }

    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const refundId = validId(request.data?.refundId);
    const creditorUid = validId(request.data?.creditorUid);
    const minorUnits = request.data?.minorUnits;
    const rawPaymentMethods = request.data?.paymentMethods;

    if (!Number.isSafeInteger(minorUnits) || minorUnits <= 0 ||
        creditorUid === uid) {
      throw new HttpsError("invalid-argument", "Invalid reimbursement.");
    }

    const paymentMethods = validateReimbursementMethods(
      rawPaymentMethods, uid, minorUnits,
    );

    const {expense, refund} = refs(tripId, expenseId, refundId);

    await db.runTransaction(async (tx) => {
      const active = await checkBudgetMembership(tx, tripId, uid);
      const existing = await tx.get(refund);
      const doc = await tx.get(expense);

      if (existing.exists) {
        throw new HttpsError("already-exists", "Reimbursement exists.");
      }

      if (!doc.exists || !active.includes(creditorUid)) {
        throw new HttpsError("failed-precondition", "Invalid creditor.");
      }

      if (doc.data()?.lifecycle === "cancelled") {
        throw new HttpsError("failed-precondition", "Expense cancelled.");
      }
      const snapshot = doc.data()!.snapshot as Snapshot;
      const debt = debtAmount(snapshot, uid, creditorUid);

      const previous = await tx.get(
        expense.collection("reimbursements"),
      );

      const pendingRevisions = await tx.get(
        expense.collection("proposals")
          .where("state", "==", "pending"),
      );
      if (!pendingRevisions.empty) {
        throw new HttpsError(
          "failed-precondition",
          "Resolve pending revision before reimbursement.",
        );
      }

      const reserved = sumReimbursements(
        previous.docs.map((item) => item.data()), uid, creditorUid,
        ["pending", ...settledStatuses],
      );

      if (!Number.isSafeInteger(reserved) ||
          debt === 0 || reserved + minorUnits > debt) {
        throw new HttpsError("failed-precondition", "Debt not available.");
      }

      // A write to the same parent document makes concurrent
      // reimbursement transactions conflict and retry.
      tx.update(expense, {
        budgetLockRevision: FieldValue.increment(1),
      });

      tx.create(refund, {
        debtorUid: uid,
        creditorUid,
        minorUnits,
        ...(paymentMethods === null ? {} : {paymentMethods}),
        currency: snapshot.total.currency,
        expenseVersion: doc.data()!.version,
        status: "pending",
        createdAt: FieldValue.serverTimestamp(),
      });
    });

    return {created: true, refundId};
  },
);

export const confirmBudgetReimbursement = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth?.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Verified user required.");
    }

    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const refundId = validId(request.data?.refundId);
    const approved = request.data?.approved;

    if (typeof approved !== "boolean") {
      throw new HttpsError("invalid-argument", "Decision required.");
    }

    const {expense, refund} = refs(tripId, expenseId, refundId);

    await db.runTransaction(async (tx) => {
      await checkBudgetMembership(tx, tripId, uid);
      const doc = await tx.get(expense);
      const refundDoc = await tx.get(refund);

      if (!doc.exists || !refundDoc.exists) {
        throw new HttpsError("not-found", "Reimbursement not found.");
      }

      const data = refundDoc.data()!;
      if (data.creditorUid !== uid || data.status !== "pending") {
        throw new HttpsError(
          "permission-denied", "Confirmation not permitted.",
        );
      }

      if (data.expenseVersion !== doc.data()!.version) {
        throw new HttpsError(
          "failed-precondition", "Expense revision changed.",
        );
      }

      if (doc.data()?.lifecycle === "cancelled") {
        throw new HttpsError("failed-precondition", "Expense cancelled.");
      }
      const snapshot = doc.data()!.snapshot as Snapshot;
      const debt = debtAmount(
        snapshot, data.debtorUid, data.creditorUid,
      );

      const previous = await tx.get(expense.collection("reimbursements"));

      const alreadyConfirmed = sumReimbursements(
        previous.docs.map((item) => item.data()),
        data.debtorUid, data.creditorUid, settledStatuses,
      );

      if (approved && alreadyConfirmed + data.minorUnits > debt) {
        throw new HttpsError(
          "failed-precondition", "Reimbursement exceeds remaining debt.",
        );
      }

      tx.update(expense, {
        budgetLockRevision: FieldValue.increment(1),
      });

      tx.update(refund, {
        status: approved ? "confirmed" : "rejected",
        decidedByUid: uid,
        decidedAt: FieldValue.serverTimestamp(),
      });
    });

    return {confirmed: approved};
  },
);
