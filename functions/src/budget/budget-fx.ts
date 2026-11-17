import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {checkBudgetMembership} from "./budget-access";
import {validId} from "./budget-validation";
import {requireVerifiedUid} from "../shared/require-verified-uid";
import {
  checkExpenseAccess,
  expenseDay,
  expenseRef,
  fetchFxRate,
  isoDate,
} from "./budget-fx-helpers";

const db = getFirestore();
const code = /^[A-Z]{3}$/;

/** Pins one authoritative historical quote to an expense, once. */
export const ensureBudgetExpenseFx = onCall(
  {region: "europe-west1", timeoutSeconds: 30},
  async (request) => {
    const uid = requireVerifiedUid(request);
    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const visibility = request.data?.visibility;
    const ref = expenseRef(tripId, expenseId, visibility, uid);
    const tripRef = db.collection("trips").doc(tripId);
    const [trip, expense] = await Promise.all([tripRef.get(), ref.get()]);
    if (!trip.exists || !expense.exists) {
      throw new HttpsError("not-found", "Trip or expense missing.");
    }
    const tripInfo = trip.data()!;
    const active = Array.isArray(tripInfo.memberUids) ?
      tripInfo.memberUids : [];
    if (tripInfo.ownerUid !== uid && !active.includes(uid)) {
      throw new HttpsError("permission-denied", "Membership required.");
    }
    const data = expense.data()!;
    checkExpenseAccess(data, uid, visibility);
    if (data.fxHistorical) {
      return {stored: true, alreadyStored: true};
    }
    const target = trip.data()?.currency;
    const source = data.snapshot?.total?.currency;
    const createdAt = expenseDay(data);
    if (typeof source !== "string" || typeof target !== "string" ||
        !code.test(source) || !code.test(target) ||
        !(createdAt instanceof Timestamp)) {
      throw new HttpsError("failed-precondition", "FX metadata unavailable.");
    }
    if (source === target) {
      return {stored: false, sameCurrency: true};
    }
    const quote = await fetchFxRate(source, target, createdAt.toDate());
    await db.runTransaction(async (tx) => {
      await checkBudgetMembership(tx, tripId, uid);
      const current = await tx.get(ref);
      if (!current.exists) {
        throw new HttpsError("not-found", "Expense removed.");
      }
      const fresh = current.data()!;
      checkExpenseAccess(fresh, uid, visibility);
      if (fresh.fxHistorical) {
        return;
      }
      if (expenseDay(fresh)?.toMillis() !== createdAt.toMillis() ||
          fresh.snapshot?.total?.currency !== source) {
        throw new HttpsError("aborted", "Expense changed during FX lock.");
      }
      tx.update(ref, {
        fxHistorical: {...quote, lockedAt: FieldValue.serverTimestamp()},
      });
    });
    return {stored: true, alreadyStored: false};
  },
);

/** An audited, explicitly manual adjustment of display FX metadata. */
export const overrideBudgetExpenseFx = onCall(
  {region: "europe-west1"},
  async (request) => {
    const uid = requireVerifiedUid(request);
    const tripId = validId(request.data?.tripId);
    const expenseId = validId(request.data?.expenseId);
    const visibility = request.data?.visibility;
    const rate = request.data?.rate;
    const reason = request.data?.reason;
    if (typeof rate !== "number" || !Number.isFinite(rate) ||
        rate <= 0 || rate > 1e9 || rate < 1e-9 ||
        typeof reason !== "string" || reason.trim().length < 3 ||
        reason.length > 400) {
      throw new HttpsError("invalid-argument", "Invalid manual FX correction.");
    }
    const ref = expenseRef(tripId, expenseId, visibility, uid);
    const tripRef = db.collection("trips").doc(tripId);
    const logRef = ref.collection("fxRateChanges").doc();
    await db.runTransaction(async (tx) => {
      await checkBudgetMembership(tx, tripId, uid);
      const [trip, expense] = await Promise.all([
        tx.get(tripRef), tx.get(ref),
      ]);
      if (!trip.exists || !expense.exists) {
        throw new HttpsError("not-found", "Expense unavailable.");
      }
      const data = expense.data()!;
      checkExpenseAccess(data, uid, visibility);
      if (data.createdByUid !== uid) {
        throw new HttpsError("permission-denied", "Expense author only.");
      }
      const base = data.snapshot?.total?.currency;
      const quote = trip.data()?.currency;
      const date = expenseDay(data);
      if (typeof base !== "string" || typeof quote !== "string" ||
          !code.test(base) || !code.test(quote) ||
          !(date instanceof Timestamp) || base === quote) {
        throw new HttpsError(
          "failed-precondition", "FX correction unavailable.",
        );
      }
      const previous = data.fxHistorical ?? null;
      const next = {
        base, quote, rate,
        date: isoDate(date.toDate()),
        requestedDate: isoDate(date.toDate()),
        source: "Manual", manual: true,
        lockedAt: FieldValue.serverTimestamp(),
      };
      tx.create(logRef, {
        actorUid: uid, previous, next,
        reason: reason.trim(), createdAt: FieldValue.serverTimestamp(),
      });
      tx.update(ref, {fxHistorical: next});
    });
    return {updated: true};
  },
);
