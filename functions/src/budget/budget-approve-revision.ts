import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {checkBudgetMembership} from "./budget-access";
import {validId, Snapshot} from "./budget-validation";

const db = getFirestore();

export const approveBudgetRevision = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth?.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Verified user required.");
    }

    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const proposalId = validId(request.data?.proposalId);
    const approved = request.data?.approved;

    if (typeof approved !== "boolean") {
      throw new HttpsError("invalid-argument", "Decision required.");
    }

    const ref = db.collection("trips").doc(tripId)
      .collection("budgetSharedExpenses").doc(expenseId);
    const proposalRef = ref.collection("proposals").doc(proposalId);

    const result = await db.runTransaction(async (tx) => {
      const activeMembers = await checkBudgetMembership(
        tx, tripId, uid,
      );
      const expense = await tx.get(ref);
      const proposal = await tx.get(proposalRef);

      if (!expense.exists || !proposal.exists) {
        throw new HttpsError("not-found", "Expense or proposal missing.");
      }

      const current = expense.data()!;
      const data = proposal.data()!;
      if (data.state !== "pending" ||
          data.baseVersion !== current.version) {
        throw new HttpsError(
          "failed-precondition", "Proposal is not current.",
        );
      }


      const required = data.requiredUids as string[];
      const previous = data.approvedUids as string[];

      if (required.some((member) => !activeMembers.includes(member))) {
        throw new HttpsError(
          "failed-precondition",
          "An affected traveler is no longer active.",
        );
      }

      if (!required.includes(uid) || previous.includes(uid)) {
        throw new HttpsError(
          "permission-denied", "Decision not permitted.",
        );
      }

      if (!approved) {
        tx.update(proposalRef, {
          state: "rejected",
          rejectedByUid: uid,
          decidedAt: FieldValue.serverTimestamp(),
        });
        return {applied: false, state: "rejected"};
      }

      const reimbursements = await tx.get(
        ref.collection("reimbursements"),
      );

      if (!reimbursements.empty) {
        throw new HttpsError(
          "failed-precondition",
          "Reimbursements prevent automatic revision.",
        );
      }

      const nextApprovals = [...previous, uid];
      if (nextApprovals.length < required.length) {
        tx.update(proposalRef, {
          approvedUids: nextApprovals,
        });
        return {applied: false, state: "pending"};
      }

      const version = (current.version as number) + 1;
      const revisionRef = ref.collection("revisions")
        .doc(String(version));

      const existingRevision = await tx.get(revisionRef);
      if (existingRevision.exists) {
        throw new HttpsError(
          "already-exists", "Revision already exists.",
        );
      }

      const nextSnapshot = data.proposedSnapshot as Snapshot;
      const oldAdvances = (current.snapshot as Snapshot).advances;
      const payerIds = new Set([
        ...Object.keys(oldAdvances), ...Object.keys(nextSnapshot.advances),
      ]);
      const samePayments = [...payerIds].every((payer) =>
        (oldAdvances[payer]?.minorUnits ?? 0) ===
        (nextSnapshot.advances[payer]?.minorUnits ?? 0));
      const paymentFields = {
        ...(samePayments && current.paymentMethods ?
          {paymentMethods: current.paymentMethods} : {}),
        ...(samePayments && current.accountPayments ?
          {accountPayments: current.accountPayments} : {}),
      };
      tx.create(revisionRef, {
        ...paymentFields,
        ...(current.expenseDate ? {expenseDate: current.expenseDate} : {}),
        number: version,
        snapshot: data.proposedSnapshot,
        actorUid: uid,
        proposalId,
        createdAt: FieldValue.serverTimestamp(),
      });

      const participantUids = [...new Set<string>([
        ...Object.keys(nextSnapshot.shares ?? {}),
        ...Object.keys(nextSnapshot.advances ?? {}),
      ])].sort();

      tx.update(ref, {
        ...(!samePayments ? {
          paymentMethods: FieldValue.delete(),
          accountPayments: FieldValue.delete(),
        } : {}),
        participantUids,
        snapshot: data.proposedSnapshot,
        version,
        updatedAt: FieldValue.serverTimestamp(),
      });

      tx.update(proposalRef, {
        approvedUids: nextApprovals,
        state: "applied",
        appliedVersion: version,
        decidedAt: FieldValue.serverTimestamp(),
      });

      return {applied: true, state: "applied", version};
    });

    return result;
  },
);
