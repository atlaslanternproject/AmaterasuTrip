import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {checkBudgetMembership} from "./budget-access";
import {validId} from "./budget-validation";

const db = getFirestore();

/** Creates a trip-wide category with normalized, deduplicated ID. */
export const createBudgetCategory = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth?.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Verified user required.");
    }
    const tripId = validId(request.data?.tripId);
    const input = request.data?.label;
    if (typeof input !== "string") {
      throw new HttpsError("invalid-argument", "Category name required.");
    }
    const label = input.trim().replace(/\s+/g, " ");
    if (label.length < 2 || label.length > 60) {
      throw new HttpsError("invalid-argument", "Invalid category name.");
    }
    const slug = label.normalize("NFKD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLowerCase().replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "").slice(0, 60).replace(/-+$/g, "");
    if (!/^[a-z0-9][a-z0-9-]{0,59}$/.test(slug)) {
      throw new HttpsError("invalid-argument", "Invalid category ID.");
    }
    const ref = db.collection("trips").doc(tripId)
      .collection("budgetCategories").doc(slug);
    const created = await db.runTransaction(async (tx) => {
      await checkBudgetMembership(tx, tripId, uid);
      const current = await tx.get(ref);
      if (current.exists) {
        return false;
      }
      tx.create(ref, {
        label,
        slug,
        createdByUid: uid,
        createdAt: FieldValue.serverTimestamp(),
      });
      return true;
    });
    return {category: `custom:${slug}`, label, created};
  },
);

/** Changes only the category, with a non-financial audit entry. */
export const updateBudgetExpenseCategory = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth?.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Verified user required.");
    }
    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const category = request.data?.category;
    const visibility = request.data?.visibility;
    const builtIn = [
      "accommodation", "food", "transport", "activities",
      "shopping", "other",
    ];
    if (typeof category !== "string" ||
        (!builtIn.includes(category) &&
         !/^custom:[a-z0-9-]{1,60}$/.test(category))) {
      throw new HttpsError("invalid-argument", "Invalid category.");
    }
    const expenseRef = visibility === "shared" ?
      db.collection("trips").doc(tripId)
        .collection("budgetSharedExpenses").doc(expenseId) :
      visibility === "private" ?
        db.collection("trips").doc(tripId)
          .collection("budgetPrivateOwners").doc(uid)
          .collection("expenses").doc(expenseId) : null;
    if (expenseRef === null) {
      throw new HttpsError("invalid-argument", "Invalid visibility.");
    }
    const logRef = expenseRef.collection("categoryChanges").doc();
    await db.runTransaction(async (tx) => {
      await checkBudgetMembership(tx, tripId, uid);
      const expense = await tx.get(expenseRef);
      if (!expense.exists || expense.data()?.lifecycle === "cancelled") {
        throw new HttpsError("not-found", "Active expense missing.");
      }
      const data = expense.data()!;
      if (data.createdByUid !== uid) {
        throw new HttpsError("permission-denied", "Expense author only.");
      }
      if (category.startsWith("custom:")) {
        const custom = await tx.get(
          db.collection("trips").doc(tripId)
            .collection("budgetCategories").doc(category.slice(7)),
        );
        if (!custom.exists) {
          throw new HttpsError("invalid-argument", "Unknown category.");
        }
      }
      if (data.category === category) {
        return;
      }
      tx.create(logRef, {
        oldCategory: data.category ?? "other",
        newCategory: category, actorUid: uid,
        createdAt: FieldValue.serverTimestamp(),
      });
      tx.update(expenseRef, {
        category,
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
    return {updated: true};
  },
);
