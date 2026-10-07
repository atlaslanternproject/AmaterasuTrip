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

const db = getFirestore();

const supportedProviders =
  new Set<string>([
    "google_drive",
    "onedrive",
    "dropbox",
  ]);

export const updateTripCloudArchive =
  onCall(
    {
      region: "europe-west1",
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

      const rawArchive =
        request.data?.archive;

      if (
        typeof rawTripId !== "string" ||
        rawTripId.trim().length === 0
      ) {
        throw new HttpsError(
          "invalid-argument",
          "A valid tripId is required.",
        );
      }

      if (
        rawArchive == null ||
        typeof rawArchive !== "object" ||
        Array.isArray(rawArchive)
      ) {
        throw new HttpsError(
          "invalid-argument",
          "A valid cloud archive is required.",
        );
      }

      const archive =
        rawArchive as
          Record<string, unknown>;

      const provider =
        archive.provider;

      const folderId =
        archive.folderId;

      const folderName =
        archive.folderName;

      if (
        typeof provider !== "string" ||
        !supportedProviders.has(provider) ||
        typeof folderId !== "string" ||
        folderId.trim().length === 0 ||
        typeof folderName !== "string" ||
        folderName.trim().length === 0
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Invalid cloud archive data.",
        );
      }

      const tripId =
        rawTripId.trim();

      const tripRef =
        db.collection("trips").doc(
          tripId,
        );

      const tripSnapshot =
        await tripRef.get();

      if (!tripSnapshot.exists) {
        throw new HttpsError(
          "not-found",
          "Trip not found.",
        );
      }

      const tripData =
        tripSnapshot.data();

      if (!isTripMember(tripData, uid)) {
        throw new HttpsError(
          "permission-denied",
          "Trip membership is required.",
        );
      }

      await tripRef.update({
        cloudArchive: {
          provider,
          folderId: folderId.trim(),
          folderName: folderName.trim(),
          folderUrl:
            typeof archive.folderUrl ===
              "string" ?
              archive.folderUrl :
              null,
          accountEmail:
            typeof archive.accountEmail ===
              "string" ?
              archive.accountEmail :
              null,
        },
        updatedAt:
          FieldValue.serverTimestamp(),
      });

      return {
        updated: true,
        tripId,
      };
    },
  );
