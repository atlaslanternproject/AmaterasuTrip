import {createHash} from "node:crypto";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";

type TripData = {
  name?: unknown;
  ownerUid?: unknown;
  memberUids?: unknown;
  startDate?: unknown;
  endDate?: unknown;
  destination?: unknown;
  currency?: unknown;
};

const db = getFirestore();

const relevantFields = [
  "name",
  "startDate",
  "endDate",
  "destination",
  "currency",
] as const;

/**
 * Converts a Firestore field into a comparable string.
 *
 * @param {unknown} value Value to normalize.
 * @return {string} Comparable representation.
 */
function comparable(value: unknown): string {
  if (value === undefined || value === null) {
    return "null";
  }

  return JSON.stringify(value);
}

/**
 * Determines whether relevant trip information has changed.
 *
 * @param {TripData} before Previous trip document.
 * @param {TripData} after Updated trip document.
 * @return {boolean} Whether a notification is required.
 */
function hasRelevantChange(
  before: TripData,
  after: TripData,
): boolean {
  return relevantFields.some((key) =>
    comparable(before[key]) !== comparable(after[key])
  );
}

/**
 * Collects unique trip members eligible for notification.
 *
 * @param {TripData} trip Updated trip document.
 * @return {string[]} Unique member identifiers.
 */
function recipients(trip: TripData): string[] {
  const result = new Set<string>();

  if (typeof trip.ownerUid === "string" &&
      trip.ownerUid.length > 0) {
    result.add(trip.ownerUid);
  }

  if (Array.isArray(trip.memberUids)) {
    for (const uid of trip.memberUids) {
      if (typeof uid === "string" && uid.length > 0) {
        result.add(uid);
      }
    }
  }

  return [...result];
}

/**
 * Publishes one personal inbox entry for each current trip member.
 * Uses an event-scoped deterministic ID to avoid duplicates.
 */
export const notifyTripInformationUpdated = onDocumentUpdated(
  {
    document: "trips/{tripId}",
    region: "europe-west1",
    retry: false,
  },
  async (event) => {
    const beforeSnapshot = event.data?.before;
    const afterSnapshot = event.data?.after;

    if (!beforeSnapshot || !afterSnapshot) {
      return;
    }

    const before = beforeSnapshot.data() as TripData;
    const after = afterSnapshot.data() as TripData;

    if (!hasRelevantChange(before, after)) {
      return;
    }

    const tripId = event.params.tripId;
    const targetUids = recipients(after);

    if (targetUids.length === 0) {
      return;
    }

    const eventKey = createHash("sha256")
      .update(`${tripId}:${event.id}`)
      .digest("hex")
      .slice(0, 40);

    const title = "Amaterasu Trip";
    const body = "Le informazioni di un viaggio sono state aggiornate.";

    for (const uid of targetUids) {
      const notificationRef = db
        .collection("viaggiatori")
        .doc(uid)
        .collection("notifications")
        .doc(`trip-info-${eventKey}`);

      // create() fails when the ID already exists.
      // This prevents duplicate inbox entries on retried events.
      let created = false;

      try {
        await notificationRef.create({
          type: "trip_update",
          category: "trip_information_changes",
          title,
          body,
          tripId,
          route: `/trips/${encodeURIComponent(tripId)}`,
          createdAt: FieldValue.serverTimestamp(),
          readAt: null,
          archivedAt: null,
          deletedAt: null,
        });
        created = true;
      } catch (error: unknown) {
        const code =
          (error as {code?: string | number})?.code;

        if (code === 6 || code === "already-exists") {
          continue;
        }

        throw error;
      }

      if (!created) {
        continue;
      }

      // Legacy Android token. A future multi-device migration
      // should replace this with a per-device token collection.
      const userSnapshot = await db
        .collection("viaggiatori")
        .doc(uid)
        .get();

      const token = userSnapshot.data()?.fcmToken;

      if (typeof token !== "string" || token.length === 0) {
        continue;
      }

      try {
        await getMessaging().send({
          token,
          notification: {
            title,
            body,
          },
          data: {
            type: "trip_update",
            tripId,
            notificationId: notificationRef.id,
          },
          android: {
            priority: "high",
          },
        });
      } catch (error: unknown) {
        // Inbox persistence must never depend on push delivery.
        const code =
          (error as {code?: string})?.code ?? "unknown";

        console.warn("Notification push not delivered", {
          code,
          notificationId: notificationRef.id,
        });
      }
    }
  },
);
