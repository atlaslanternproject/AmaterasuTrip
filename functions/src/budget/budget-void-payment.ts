import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {checkBudgetMembership} from "./budget-access";
import {declaredKind, validId, voidedStatus} from "./budget-validation";
import {validateReason} from "./budget-payment-details";
import {writtenOffStatus} from "./budget-debt-closure";
import {requireVerifiedUid} from "../shared/require-verified-uid";

const db = getFirestore();

/**
 * The creditor cancels a payment they declared. Nothing is deleted: the
 * record becomes "voided" with who, when and why, and the remaining
 * debt ignores it from then on.
 */
export const voidBudgetPayment = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = requireVerifiedUid(request);

    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const refundId = validId(request.data?.refundId);
    const reason = validateReason(request.data?.reason);

    const expense = db.collection("trips").doc(tripId)
      .collection("budgetSharedExpenses").doc(expenseId);
    const refund = expense.collection("reimbursements").doc(refundId);

    await db.runTransaction(async (tx) => {
      await checkBudgetMembership(tx, tripId, uid);
      const [doc, record, all] = await Promise.all([
        tx.get(expense), tx.get(refund),
        tx.get(expense.collection("reimbursements")),
      ]);

      if (!doc.exists || !record.exists) {
        throw new HttpsError("not-found", "Payment not found.");
      }
      const data = record.data()!;
      if (data.kind !== declaredKind || data.creditorUid !== uid) {
        throw new HttpsError("permission-denied", "Creditor only.");
      }
      if (data.status !== "confirmed") {
        throw new HttpsError("failed-precondition", "Payment not active.");
      }
      // A debt closed for a former member (B8.6) must not reopen.
      const closed = all.docs.some((item) => {
        const other = item.data();
        return other.status === writtenOffStatus &&
          other.debtorUid === data.debtorUid &&
          other.creditorUid === data.creditorUid;
      });
      if (closed) {
        throw new HttpsError("failed-precondition", "Debt already closed.");
      }

      tx.update(expense, {budgetLockRevision: FieldValue.increment(1)});
      tx.update(refund, {
        status: voidedStatus,
        voidedByUid: uid,
        voidedAt: FieldValue.serverTimestamp(),
        voidReason: reason,
      });
    });

    return {voided: true, refundId};
  },
);
