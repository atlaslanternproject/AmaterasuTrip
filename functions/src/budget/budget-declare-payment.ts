import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {checkBudgetMembership} from "./budget-access";
import {
  declaredKind, debtAmount, settledStatuses, Snapshot, sumReimbursements,
  validId,
} from "./budget-validation";
import {validateReimbursementMethods} from "./budget-reimbursement-methods";
import {validateNote, validatePaidOn} from "./budget-payment-details";
import {requireVerifiedUid} from "../shared/require-verified-uid";

const db = getFirestore();

/**
 * The creditor of a debt declares that the debtor paid ("X paid me"),
 * even if the debtor never opened the app. The record is created
 * already confirmed, with origin "creditor". The amount must be above
 * zero and not above the remaining debt, computed in the transaction
 * from settled records only. A pending request of the debtor stays as
 * it is: confirming it later is checked against the new remaining debt.
 */
export const declareBudgetPayment = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = requireVerifiedUid(request);

    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const refundId = validId(request.data?.refundId);
    const debtorUid = validId(request.data?.debtorUid);
    const minorUnits = request.data?.minorUnits;

    if (!Number.isSafeInteger(minorUnits) || minorUnits <= 0 ||
        debtorUid === uid) {
      throw new HttpsError("invalid-argument", "Invalid payment.");
    }

    const paidOn = validatePaidOn(request.data?.paidOn, new Date());
    const note = validateNote(request.data?.note);
    const paymentMethods = validateReimbursementMethods(
      request.data?.paymentMethods, debtorUid, minorUnits,
    );

    const expense = db.collection("trips").doc(tripId)
      .collection("budgetSharedExpenses").doc(expenseId);
    const refund = expense.collection("reimbursements").doc(refundId);

    const remainingAfter = await db.runTransaction(async (tx) => {
      const active = await checkBudgetMembership(tx, tripId, uid);
      const [existing, doc, previous, pendingRevisions] = await Promise.all([
        tx.get(refund),
        tx.get(expense),
        tx.get(expense.collection("reimbursements")),
        tx.get(expense.collection("proposals")
          .where("state", "==", "pending")),
      ]);

      if (existing.exists) {
        throw new HttpsError("already-exists", "Payment exists.");
      }
      if (!doc.exists) {
        throw new HttpsError("not-found", "Expense not found.");
      }
      if (doc.data()?.lifecycle === "cancelled") {
        throw new HttpsError("failed-precondition", "Expense cancelled.");
      }
      if (!active.includes(debtorUid)) {
        throw new HttpsError(
          "failed-precondition", "Debtor is not a trip member.",
        );
      }
      if (!pendingRevisions.empty) {
        throw new HttpsError(
          "failed-precondition",
          "Resolve pending revision before reimbursement.",
        );
      }

      const snapshot = doc.data()!.snapshot as Snapshot;
      const debt = debtAmount(snapshot, debtorUid, uid);
      if (debt === 0) {
        throw new HttpsError("permission-denied", "Creditor only.");
      }

      const settled = sumReimbursements(
        previous.docs.map((item) => item.data()), debtorUid, uid,
        settledStatuses,
      );
      const remaining = debt - settled;
      if (!Number.isSafeInteger(remaining) || remaining <= 0) {
        throw new HttpsError("failed-precondition", "Debt already settled.");
      }
      if (minorUnits > remaining) {
        throw new HttpsError(
          "failed-precondition", "Amount exceeds remaining debt.",
        );
      }

      // A write to the same parent document makes concurrent
      // declarations and reimbursements conflict and retry.
      tx.update(expense, {budgetLockRevision: FieldValue.increment(1)});
      tx.create(refund, {
        kind: declaredKind,
        origin: "creditor",
        debtorUid,
        creditorUid: uid,
        minorUnits,
        ...(paymentMethods === null ? {} : {paymentMethods}),
        currency: snapshot.total.currency,
        expenseVersion: doc.data()!.version,
        status: "confirmed",
        paidOn,
        ...(note === null ? {} : {note}),
        recordedByUid: uid,
        decidedByUid: uid,
        createdAt: FieldValue.serverTimestamp(),
        decidedAt: FieldValue.serverTimestamp(),
      });
      return remaining - minorUnits;
    });

    return {declared: true, refundId, remainingMinor: remainingAfter};
  },
);
