import {DocumentData} from "firebase-admin/firestore";

const excludedRootFields = new Set<string>([
  "ownerUid",
  "memberUids",
  "status",
  "createdAt",
  "updatedAt",
  "cloudArchive",
  "coverUrl",
  "coverPath",
]);

const excludedSubcollections = new Set<string>([
  "members",
]);

const excludedExternalReferenceFields =
  new Set<string>([
    "cloudArchive",
    "coverUrl",
    "coverPath",
    "externalFileId",
    "externalFileUrl",
    "externalProvider",
    "providerFileId",
    "providerFileUrl",
    "driveFileId",
    "driveWebViewLink",
    "oneDriveFileId",
    "dropboxFileId",
    "storagePath",
    "downloadUrl",
  ]);

/**
 * Returns whether a Firestore subcollection belongs
 * to duplicable trip content.
 *
 * @param {string} collectionId Firestore collection ID.
 * @return {boolean} Whether the collection must be copied.
 */
export function shouldCopyTripSubcollection(
  collectionId: string,
): boolean {
  return !excludedSubcollections.has(collectionId);
}

/**
 * Checks whether a value is a plain object.
 *
 * @param {unknown} value Value to inspect.
 * @return {boolean} Whether the value is a plain object.
 */
function isPlainObject(
  value: unknown,
): value is Record<string, unknown> {
  if (
    value == null ||
    typeof value !== "object"
  ) {
    return false;
  }

  const prototype =
    Object.getPrototypeOf(value);

  return prototype === Object.prototype ||
    prototype === null;
}

/**
 * Sanitises one Firestore value.
 *
 * @param {unknown} value Source value.
 * @param {string} key Field name.
 * @param {string} sourceTripId Original trip ID.
 * @param {string} targetTripId Duplicated trip ID.
 * @return {unknown} Sanitised value or undefined.
 */
function sanitiseValue(
  value: unknown,
  key: string,
  sourceTripId: string,
  targetTripId: string,
): unknown {
  if (
    excludedExternalReferenceFields.has(key)
  ) {
    return undefined;
  }

  if (
    key === "tripId" &&
    value === sourceTripId
  ) {
    return targetTripId;
  }

  if (Array.isArray(value)) {
    return value
      .map((item) =>
        sanitiseValue(
          item,
          "",
          sourceTripId,
          targetTripId,
        ),
      )
      .filter((item) =>
        item !== undefined,
      );
  }

  if (isPlainObject(value)) {
    const result:
      Record<string, unknown> = {};

    for (
      const [childKey, childValue]
      of Object.entries(value)
    ) {
      const sanitised =
        sanitiseValue(
          childValue,
          childKey,
          sourceTripId,
          targetTripId,
        );

      if (sanitised !== undefined) {
        result[childKey] = sanitised;
      }
    }

    return result;
  }

  return value;
}

/**
 * Sanitises a normal trip-content document.
 *
 * @param {Object} data Firestore document data.
 * @param {string} sourceTripId Original trip ID.
 * @param {string} targetTripId Duplicated trip ID.
 * @return {Object} Sanitised Firestore data.
 */
export function sanitiseTripContentData(
  data: DocumentData,
  sourceTripId: string,
  targetTripId: string,
): DocumentData {
  const result: DocumentData = {};

  for (
    const [key, value]
    of Object.entries(data)
  ) {
    const sanitised =
      sanitiseValue(
        value,
        key,
        sourceTripId,
        targetTripId,
      );

    if (sanitised !== undefined) {
      result[key] = sanitised;
    }
  }

  return result;
}

/**
 * Sanitises the root trip document.
 *
 * @param {Object} data Firestore trip data.
 * @param {string} sourceTripId Original trip ID.
 * @param {string} targetTripId Duplicated trip ID.
 * @return {Object} Sanitised root document data.
 */
export function sanitiseTripRootData(
  data: DocumentData,
  sourceTripId: string,
  targetTripId: string,
): DocumentData {
  const result =
    sanitiseTripContentData(
      data,
      sourceTripId,
      targetTripId,
    );

  for (
    const field
    of excludedRootFields
  ) {
    delete result[field];
  }

  return result;
}
