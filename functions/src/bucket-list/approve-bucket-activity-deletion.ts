import {randomUUID} from "crypto";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";

// AMATERASU_BUCKET_DELETE_A3
const db = getFirestore();

// The callable has a 300-second timeout. A lease must outlive the
// maximum execution time so two recursive deletions cannot overlap.
const LEASE_MS = 15 * 60 * 1000;

/**
 * Validates an individual Firestore document identifier.
 *
 * @param {unknown} value Identifier to validate.
 * @return {boolean} Whether the identifier is safe.
 */
function validId(value: unknown): value is string {
  return typeof value === "string" &&
    value.length > 0 &&
    value.length <= 300 &&
    value.trim() === value &&
    value !== "." &&
    value !== ".." &&
    !value.includes("/");
}

/**
 * Approves a pending request and physically deletes the activity.
 *
 * The audit document survives deletion and permits controlled retries.
 * Concurrent invocations cannot acquire the same active lease.
 */
export const approveBucketActivityDeletion = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 300,
  },
  async (request) => {
    const uid = request.auth?.uid;

    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication required.",
      );
    }

    const tripId: unknown = request.data?.tripId;
    const activityId: unknown = request.data?.activityId;
    const requestId: unknown = request.data?.requestId;

    if (!validId(tripId) ||
        !validId(activityId) ||
        !validId(requestId)) {
      throw new HttpsError(
        "invalid-argument",
        "Invalid deletion identifiers.",
      );
    }

    const tripRef = db.collection("trips").doc(tripId);
    const activityRef = tripRef.collection("bucketList").doc(activityId);
    const requestRef = activityRef
      .collection("deletionRequests")
      .doc(requestId);

    // Stored outside the activity subtree, so recursiveDelete
    // does not remove the audit or its recovery information.
    const auditRef = tripRef
      .collection("bucketDeletionAudit")
      .doc(activityId);

    const attemptId = randomUUID();

    const operation = await db.runTransaction(async (tx) => {
      const trip = await tx.get(tripRef);
      const audit = await tx.get(auditRef);

      if (!trip.exists) {
        throw new HttpsError("not-found", "Trip not found.");
      }

      if (trip.data()?.ownerUid !== uid) {
        throw new HttpsError(
          "permission-denied",
          "Only the trip owner can approve deletion.",
        );
      }

      if (audit.exists) {
        const data = audit.data();

        if (data?.tripId !== tripId ||
            data?.activityId !== activityId ||
            data?.requestId !== requestId) {
          throw new HttpsError(
            "failed-precondition",
            "Deletion operation mismatch.",
          );
        }

        if (data?.status === "completed") {
          const currentActivity = await tx.get(activityRef);

          if (currentActivity.exists) {
            throw new HttpsError(
              "failed-precondition",
              "Activity exists after completed deletion.",
            );
          }

          return "completed";
        }

        if (data?.status === "processing") {
          const startedAt = data?.startedAt?.toMillis?.();

          // Missing/invalid lease timestamps are NOT treated as
          // expired: require inspection instead of unsafe takeover.
          if (typeof startedAt !== "number") {
            throw new HttpsError(
              "failed-precondition",
              "Deletion lease requires manual inspection.",
            );
          }

          if (Date.now() - startedAt < LEASE_MS) {
            throw new HttpsError(
              "aborted",
              "Deletion is already processing.",
            );
          }
        } else if (data?.status !== "failed") {
          throw new HttpsError(
            "failed-precondition",
            "Invalid deletion state.",
          );
        }

        // Atomic lease takeover, after the prior execution's
        // maximum runtime plus a safety margin.
        tx.update(auditRef, {
          status: "processing",
          attemptId,
          startedAt: FieldValue.serverTimestamp(),
          retryCount: FieldValue.increment(1),
        });

        return "process";
      }

      const activity = await tx.get(activityRef);
      const deletion = await tx.get(requestRef);
      const deletionData = deletion.data();

      if (!activity.exists) {
        throw new HttpsError("not-found", "Activity not found.");
      }

      if (!deletion.exists ||
          deletionData?.activityId !== activityId ||
          deletionData?.requestedByUid !== requestId ||
          deletionData?.status !== "pending") {
        throw new HttpsError(
          "failed-precondition",
          "A matching pending request is required.",
        );
      }

      tx.create(auditRef, {
        tripId,
        activityId,
        requestId,
        requestedByUid: requestId,
        approvedByUid: uid,
        status: "processing",
        attemptId,
        startedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
        retryCount: 0,
      });

      return "process";
    });

    if (operation === "completed") {
      return {
        deleted: true,
        alreadyCompleted: true,
      };
    }

    try {
      // REAL Firestore deletion, including votes,
      // deletionRequests and any other nested collections.
      await db.recursiveDelete(activityRef);

      await db.runTransaction(async (tx) => {
        const audit = await tx.get(auditRef);

        if (audit.data()?.attemptId !== attemptId ||
            audit.data()?.status !== "processing") {
          throw new Error("Deletion lease no longer owned.");
        }

        tx.update(auditRef, {
          status: "completed",
          completedAt: FieldValue.serverTimestamp(),
        });
      });

      return {
        deleted: true,
        alreadyCompleted: false,
      };
    } catch {
      try {
        await db.runTransaction(async (tx) => {
          const audit = await tx.get(auditRef);

          if (audit.data()?.attemptId === attemptId &&
              audit.data()?.status === "processing") {
            tx.update(auditRef, {
              status: "failed",
              failedAt: FieldValue.serverTimestamp(),
            });
          }
        });
      } catch {
        // A processing lease can be reclaimed after LEASE_MS.
      }

      throw new HttpsError(
        "internal",
        "Deletion incomplete. Retry may be required.",
      );
    }
  },
);
