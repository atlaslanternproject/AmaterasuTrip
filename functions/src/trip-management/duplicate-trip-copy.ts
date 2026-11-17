import {
  CollectionReference,
  DocumentData,
  DocumentReference,
  getFirestore,
} from "firebase-admin/firestore";

import {
  sanitiseTripContentData,
  shouldCopyTripSubcollection,
} from "./trip-duplication-policy";

const db = getFirestore();

/**
 * Recursively copies a Firestore collection.
 *
 * @param {Object} sourceCollection Source collection.
 * @param {Object} targetCollection Destination collection.
 * @param {string} sourceTripId Original trip ID.
 * @param {string} targetTripId Duplicated trip ID.
 * @return {Promise<void>} Completion future.
 */
export async function copyCollectionTree(
  sourceCollection:
    CollectionReference<DocumentData>,
  targetCollection:
    CollectionReference<DocumentData>,
  sourceTripId: string,
  targetTripId: string,
): Promise<void> {
  const sourceSnapshot =
    await sourceCollection.get();

  for (
    const sourceDocument
    of sourceSnapshot.docs
  ) {
    const targetDocument =
      targetCollection.doc(
        sourceDocument.id,
      );

    const cleanData =
      sanitiseTripContentData(
        sourceDocument.data(),
        sourceTripId,
        targetTripId,
      );

    await targetDocument.set(
      cleanData,
    );

    const childCollections =
      await sourceDocument.ref
        .listCollections();

    for (
      const childCollection
      of childCollections
    ) {
      if (
        !shouldCopyTripSubcollection(
          childCollection.id,
        )
      ) {
        continue;
      }

      await copyCollectionTree(
        childCollection,
        targetDocument.collection(
          childCollection.id,
        ),
        sourceTripId,
        targetTripId,
      );
    }
  }
}

/**
 * Removes a partially created duplicate.
 *
 * @param {Object} targetRef Target trip reference.
 * @return {Promise<void>} Completion future.
 */
export async function cleanupFailedDuplicate(
  targetRef:
    DocumentReference<DocumentData>,
): Promise<void> {
  const collections =
    await targetRef.listCollections();

  for (
    const collection
    of collections
  ) {
    await db.recursiveDelete(
      collection,
    );
  }

  const snapshot =
    await targetRef.get();

  if (snapshot.exists) {
    await targetRef.delete();
  }
}
