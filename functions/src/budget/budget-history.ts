import {getFirestore} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {checkBudgetMembership} from "./budget-access";
import {validId} from "./budget-validation";
import {
  buildExpenseHistory, sortHistory, HistoryEvent, HistorySources,
} from "./budget-history-events";

const db = getFirestore();
const maxEvents = 500;

/**
 * Loads history sources of one expense.
 * @param {FirebaseFirestore.DocumentReference} ref Expense reference.
 * @return {Promise<HistorySources>} Records.
 */
async function loadSources(
  ref: FirebaseFirestore.DocumentReference,
): Promise<HistorySources> {
  const [revisions, reimbursements, cancellation, log, fx] =
    await Promise.all([
      ref.collection("revisions").get(),
      ref.collection("reimbursements").get(),
      ref.collection("cancellation").doc("current").get(),
      ref.collection("cancellationLog").get(),
      ref.collection("fxRateChanges").get(),
    ]);
  const data = (snap: FirebaseFirestore.QuerySnapshot) =>
    snap.docs.map((doc) => doc.data());
  return {
    revisions: data(revisions),
    reimbursements: data(reimbursements),
    cancellation: cancellation.exists ? cancellation.data()! : null,
    cancellationLog: data(log),
    fxRateChanges: data(fx),
  };
}

/**
 * B8.6: history of one expense, or of the whole trip, limited to what the
 * caller may see: shared expenses they take part in and their own private
 * expenses. Former members are not active members and get nothing.
 */
export const listBudgetHistory = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth?.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Verified user required.");
    }
    const tripId = validId(request.data?.tripId);
    await db.runTransaction((tx) => checkBudgetMembership(tx, tripId, uid));

    const trip = db.collection("trips").doc(tripId);
    const shared = trip.collection("budgetSharedExpenses");
    const privateExpenses = trip.collection("budgetPrivateOwners").doc(uid)
      .collection("expenses");

    let docs: {doc: FirebaseFirestore.DocumentSnapshot; private: boolean}[];
    if (request.data?.expenseId !== undefined) {
      const expenseId = validId(request.data.expenseId);
      const isPrivate = request.data?.visibility === "private";
      const doc = await (isPrivate ? privateExpenses : shared)
        .doc(expenseId).get();
      if (!doc.exists) {
        throw new HttpsError("not-found", "Expense not found.");
      }
      const participants = doc.get("participantUids");
      if (!isPrivate &&
          !(Array.isArray(participants) && participants.includes(uid))) {
        throw new HttpsError("permission-denied", "Participants only.");
      }
      docs = [{doc, private: isPrivate}];
    } else {
      const [sharedDocs, ownDocs] = await Promise.all([
        shared.where("participantUids", "array-contains", uid).get(),
        privateExpenses.get(),
      ]);
      docs = [
        ...sharedDocs.docs.map((doc) => ({doc, private: false})),
        ...ownDocs.docs.map((doc) => ({doc, private: true})),
      ];
    }

    const expenses: Record<string, unknown> = {};
    const names: Record<string, string> = {};
    const all: HistoryEvent[] = [];
    await Promise.all(docs.map(async (item) => {
      const data = item.doc.data()!;
      const sources = await loadSources(item.doc.ref);
      all.push(...buildExpenseHistory(item.doc.id, data, sources));
      expenses[item.doc.id] = {
        title: typeof data.title === "string" ? data.title : "",
        visibility: item.private ? "private" : "shared",
      };
      for (const [id, name] of Object.entries(data.participantNames ?? {})) {
        if (typeof name === "string") names[id] = name;
      }
    }));

    return {
      events: sortHistory(all).slice(0, maxEvents),
      expenses,
      names,
    };
  },
);
