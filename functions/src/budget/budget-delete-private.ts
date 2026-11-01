import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {checkBudgetMembership} from "./budget-access";
import {validId} from "./budget-validation";

const db = getFirestore();
export const cancelPrivateBudgetExpense = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth?.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Verified user required.");
    }
    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const ref = db.collection("trips").doc(tripId)
      .collection("budgetPrivateOwners").doc(uid)
      .collection("expenses").doc(expenseId);
    await db.runTransaction(async (tx) => {
      await checkBudgetMembership(tx, tripId, uid);
      const doc = await tx.get(ref);
      if (!doc.exists) throw new HttpsError("not-found", "Expense missing.");
      if (doc.data()?.lifecycle === "cancelled") {
        throw new HttpsError(
          "failed-precondition", "Already cancelled.",
        );
      }
      tx.update(ref, {
        lifecycle: "cancelled", cancelledByUid: uid,
        cancelledAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
    return {cancelled: true};
  },
);
