import {
  FieldValue,
  getFirestore,
} from "firebase-admin/firestore";

import {
  HttpsError,
  onCall,
} from "firebase-functions/v2/https";

import {
  isTripMember,
} from "../shared/trip-access";

import {
  sanitiseTripRootData,
  shouldCopyTripSubcollection,
} from "./trip-duplication-policy";

import {
  cleanupFailedDuplicate,
  copyCollectionTree,
} from "./duplicate-trip-copy";

const db = getFirestore();

export const duplicateTrip = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 300,
  },
  async (request) => {
    const uid = request.auth?.uid;

    if (uid == null) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication is required.",
      );
    }

    const rawTripId =
      request.data?.tripId;

    const rawDuplicateName =
      request.data?.duplicateName;

    if (
      typeof rawTripId !== "string" ||
      rawTripId.trim().length === 0 ||
      typeof rawDuplicateName !== "string" ||
      rawDuplicateName.trim().length === 0
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Trip ID and duplicate name are required.",
      );
    }

    const tripId =
      rawTripId.trim();

    const duplicateName =
      rawDuplicateName.trim();

    if (duplicateName.length > 150) {
      throw new HttpsError(
        "invalid-argument",
        "Duplicate trip name is too long.",
      );
    }

    const sourceRef =
      db.collection("trips").doc(
        tripId,
      );

    const sourceSnapshot =
      await sourceRef.get();

    if (!sourceSnapshot.exists) {
      throw new HttpsError(
        "not-found",
        "Trip not found.",
      );
    }

    const sourceData =
      sourceSnapshot.data();

    if (!isTripMember(sourceData, uid)) {
      throw new HttpsError(
        "permission-denied",
        "Trip membership is required.",
      );
    }

    if (sourceData == null) {
      throw new HttpsError(
        "not-found",
        "Trip data not found.",
      );
    }

    const targetRef =
      db.collection("trips").doc();

    const newTripId =
      targetRef.id;

    try {
      const rootCollections =
        await sourceRef.listCollections();

      for (
        const sourceCollection
        of rootCollections
      ) {
        if (
          !shouldCopyTripSubcollection(
            sourceCollection.id,
          )
        ) {
          continue;
        }

        await copyCollectionTree(
          sourceCollection,
          targetRef.collection(
            sourceCollection.id,
          ),
          tripId,
          newTripId,
        );
      }

      const targetRootData =
        sanitiseTripRootData(
          sourceData,
          tripId,
          newTripId,
        );

      targetRootData.name =
        duplicateName;

      targetRootData.ownerUid =
        uid;

      targetRootData.memberUids =
        [uid];

      targetRootData.status =
        "active";

      targetRootData.createdAt =
        FieldValue.serverTimestamp();

      targetRootData.updatedAt =
        FieldValue.serverTimestamp();

      await targetRef.set(
        targetRootData,
      );

      await targetRef
        .collection("members")
        .doc(uid)
        .set({
          uid,
          role: "admin",
          joinedAt:
            FieldValue.serverTimestamp(),
        });

      return {
        duplicated: true,
        sourceTripId: tripId,
        newTripId,
      };
    } catch (error) {
      try {
        await cleanupFailedDuplicate(
          targetRef,
        );
      } catch {
        // Best-effort cleanup.
      }

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "Unable to duplicate the trip.",
      );
    }
  },
);
