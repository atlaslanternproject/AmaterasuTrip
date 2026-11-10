import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {checkBudgetMembership} from "./budget-access";
import {
  validId, debtAmount, Snapshot, settledStatuses, sumReimbursements,
} from "./budget-validation";

const db = getFirestore();

/** Status of a closure record in the reimbursements collection. */
export const writtenOffStatus = "writtenOff";

/**
 * B8.6: the creditor closes the remaining debt of a traveler who left the
 * trip. The original debt (expense snapshot) is never changed: a tracked
 * record (who, when, why, how much) is added next to the reimbursements
 * and counts as settled from then on.
 */
export const closeBudgetDebt = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth?.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Verified user required.");
    }

    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const closureId = validId(request.data?.closureId);
    const debtorUid = validId(request.data?.debtorUid);
    const reason = request.data?.reason;

    if (typeof reason !== "string" || reason.trim().length < 3 ||
        reason.length > 400 || debtorUid === uid) {
      throw new HttpsError("invalid-argument", "Invalid debt closure.");
    }

    const expense = db.collection("trips").doc(tripId)
      .collection("budgetSharedExpenses").doc(expenseId);
    const closure = expense.collection("reimbursements").doc(closureId);

    const closed = await db.runTransaction(async (tx) => {
      const active = await checkBudgetMembership(tx, tripId, uid);
      const [doc, existing, previous] = await Promise.all([
        tx.get(expense), tx.get(closure),
        tx.get(expense.collection("reimbursements")),
      ]);

      if (existing.exists) {
        throw new HttpsError("already-exists", "Record exists.");
      }
      if (!doc.exists) {
        throw new HttpsError("not-found", "Expense not found.");
      }
      if (doc.data()?.lifecycle === "cancelled") {
        throw new HttpsError("failed-precondition", "Expense cancelled.");
      }
      if (active.includes(debtorUid)) {
        throw new HttpsError(
          "failed-precondition", "Debtor is still a trip member.",
        );
      }

      const snapshot = doc.data()!.snapshot as Snapshot;
      const debt = debtAmount(snapshot, debtorUid, uid);
      if (debt === 0) {
        throw new HttpsError("permission-denied", "Creditor only.");
      }

      const records = previous.docs.map((item) => item.data());
      if (sumReimbursements(records, debtorUid, uid, ["pending"]) > 0) {
        throw new HttpsError(
          "failed-precondition", "Decide pending reimbursements first.",
        );
      }
      const remaining = debt -
        sumReimbursements(records, debtorUid, uid, settledStatuses);
      if (remaining <= 0) {
        throw new HttpsError("failed-precondition", "Debt already settled.");
      }

      tx.update(expense, {budgetLockRevision: FieldValue.increment(1)});
      tx.create(closure, {
        kind: "closure",
        debtorUid,
        creditorUid: uid,
        minorUnits: remaining,
        originalDebtMinor: debt,
        currency: snapshot.total.currency,
        expenseVersion: doc.data()!.version,
        status: writtenOffStatus,
        reason: reason.trim(),
        decidedByUid: uid,
        createdAt: FieldValue.serverTimestamp(),
        decidedAt: FieldValue.serverTimestamp(),
      });
      return remaining;
    });

    return {closed: true, minorUnits: closed};
  },
);
