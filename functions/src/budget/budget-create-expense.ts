import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {checkBudgetMembership} from "./budget-access";
import {validId, validateSnapshot} from "./budget-validation";

const db = getFirestore();

export const createBudgetExpense = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth?.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Verified user required.");
    }

    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const visibility = request.data?.visibility;

    if (visibility !== "shared" && visibility !== "private") {
      throw new HttpsError("invalid-argument", "Invalid visibility.");
    }

    const snapshot = validateSnapshot(request.data?.snapshot);

    // Optional metadata remains backward-compatible with expenses
    // created by previous clients and integration tests.
    const rawTitle = request.data?.title;
    const rawCategory = request.data?.category;
    const rawNotes = request.data?.notes;

    if (rawTitle !== undefined &&
        (typeof rawTitle !== "string" ||
         rawTitle.trim().length === 0 ||
         rawTitle.trim().length > 100)) {
      throw new HttpsError("invalid-argument", "Invalid expense title.");
    }

    const categories = [
      "accommodation",
      "food",
      "transport",
      "activities",
      "shopping",
      "other",
    ];

    if (rawCategory !== undefined &&
        (typeof rawCategory !== "string" ||
         (!categories.includes(rawCategory) &&
          !/^custom:[a-z0-9-]{1,60}$/.test(rawCategory)))) {
      throw new HttpsError("invalid-argument", "Invalid expense category.");
    }

    if (rawNotes !== undefined &&
        (typeof rawNotes !== "string" ||
         rawNotes.length > 2000)) {
      throw new HttpsError("invalid-argument", "Invalid expense notes.");
    }

    const title = typeof rawTitle === "string" ?
      rawTitle.trim() : "Spesa";
    const category = typeof rawCategory === "string" ?
      rawCategory : "other";
    const notes = typeof rawNotes === "string" ?
      rawNotes.trim() : "";

    const collection = visibility === "shared" ?
      db.collection("trips").doc(tripId)
        .collection("budgetSharedExpenses") :
      db.collection("trips").doc(tripId)
        .collection("budgetPrivateOwners").doc(uid)
        .collection("expenses");

    const expenseRef = collection.doc(expenseId);

    await db.runTransaction(async (tx) => {
      const active = await checkBudgetMembership(tx, tripId, uid);
      const existing = await tx.get(expenseRef);

      if (existing.exists) {
        throw new HttpsError("already-exists", "Expense exists.");
      }

      if (category.startsWith("custom:")) {
        const categoryRef = db.collection("trips").doc(tripId)
          .collection("budgetCategories").doc(category.slice(7));
        const categoryDoc = await tx.get(categoryRef);
        if (!categoryDoc.exists) {
          throw new HttpsError("invalid-argument", "Unknown custom category.");
        }
      }

      const participants = new Set([
        ...Object.keys(snapshot.shares),
        ...Object.keys(snapshot.advances),
      ]);

      // Until payer approval is implemented, only the authenticated
      // creator may register an actual supplier payment.
      const unauthorizedPayers = Object.entries(snapshot.advances)
        .some(([payerUid, amount]) =>
          payerUid !== uid && amount.minorUnits > 0
        );

      if (unauthorizedPayers) {
        throw new HttpsError(
          "failed-precondition",
          "Another traveler's payment requires their approval.",
        );
      }

      if (visibility === "private") {
        if (participants.size !== 1 || !participants.has(uid)) {
          throw new HttpsError(
            "invalid-argument", "Private expense must be personal.",
          );
        }
      } else if ([...participants].some(
        (member) => !active.includes(member)
      )) {
        throw new HttpsError(
          "invalid-argument", "Unknown expense participant.",
        );
      }

      tx.create(expenseRef, {
        participantUids: [...participants].sort(),
        title,
        category,
        notes,
        createdByUid: uid,
        visibility,
        snapshot,
        version: 1,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      tx.create(expenseRef.collection("revisions").doc("1"), {
        number: 1,
        snapshot,
        actorUid: uid,
        createdAt: FieldValue.serverTimestamp(),
      });
    });

    return {created: true, expenseId, version: 1};
  },
);
