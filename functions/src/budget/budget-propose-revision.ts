import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {checkBudgetMembership} from "./budget-access";
import {validId, validateSnapshot, Snapshot} from "./budget-validation";

const db = getFirestore();

export const proposeBudgetRevision = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth?.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Verified user required.");
    }

    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const proposalId = validId(request.data?.proposalId);
    const snapshot = validateSnapshot(request.data?.snapshot);

    const ref = db.collection("trips").doc(tripId)
      .collection("budgetSharedExpenses").doc(expenseId);
    const proposalRef = ref.collection("proposals").doc(proposalId);

    await db.runTransaction(async (tx) => {
      const active = await checkBudgetMembership(tx, tripId, uid);
      const expense = await tx.get(ref);
      const existing = await tx.get(proposalRef);

      if (!expense.exists) {
        throw new HttpsError("not-found", "Expense not found.");
      }
      if (existing.exists) {
        throw new HttpsError("already-exists", "Proposal exists.");
      }
      const data = expense.data()!;
      if (data.lifecycle === "cancelled") {
        throw new HttpsError("failed-precondition", "Expense cancelled.");
      }
      if (data.createdByUid !== uid) {
        throw new HttpsError(
          "permission-denied", "Only creator can modify expense.",
        );
      }

      const old = data.snapshot as Snapshot;
      if (snapshot.total.currency !== old.total.currency) {
        throw new HttpsError(
          "failed-precondition", "Currency change requires new expense.",
        );
      }

      // A revised payment cannot be attributed to a traveler
      // without a dedicated payer-approval workflow.
      for (const [payerUid, amount] of Object.entries(snapshot.advances)) {
        if (payerUid !== uid && amount.minorUnits > 0) {
          throw new HttpsError(
            "failed-precondition",
            "Other payer advances require explicit approval.",
          );
        }
      }
      const required = [...new Set([
        ...Object.keys(old.shares),
        ...Object.keys(old.advances),
        ...Object.keys(snapshot.shares),
        ...Object.keys(snapshot.advances),
      ])].sort();

      if (required.some((member) => !active.includes(member))) {
        throw new HttpsError(
          "failed-precondition", "Affected traveler is not active.",
        );
      }

      // Any reimbursement locks financial revision until
      // it has been handled by a dedicated correction workflow.
      const reimbursements = await tx.get(
        ref.collection("reimbursements"),
      );
      if (!reimbursements.empty) {
        throw new HttpsError(
          "failed-precondition",
          "Confirmed reimbursements require separate correction.",
        );
      }

      const pending = await tx.get(
        ref.collection("proposals")
          .where("state", "==", "pending"),
      );
      if (!pending.empty) {
        throw new HttpsError(
          "failed-precondition",
          "Another revision is already pending.",
        );
      }

      tx.create(proposalRef, {
        baseVersion: data.version,
        proposedSnapshot: snapshot,
        requiredUids: required,
        approvedUids: [],
        state: "pending",
        createdByUid: uid,
        createdAt: FieldValue.serverTimestamp(),
      });
    });

    return {proposed: true, proposalId};
  },
);
