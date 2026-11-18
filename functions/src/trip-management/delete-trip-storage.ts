// Eliminazione di un viaggio: quali file di Storage cancellare e come.
// Copertine del viaggio: users/{uid}/trips/{tripId}/cover/ per il
// proprietario e ogni membro, più la copertina attuale se è fuori da
// questi percorsi (per esempio caricata da un ex membro).

/** Piano dei file da cancellare per un viaggio. */
export type TripStoragePlan = {
  prefixes: string[];
  extraPaths: string[];
};

/** Errore per dati che non permettono di costruire percorsi sicuri. */
export class TripStoragePlanError extends Error {}

/**
 * Checks that a value can be used as one segment of a Storage path.
 *
 * @param {unknown} value Candidate segment.
 * @return {boolean} Whether it is a non-empty segment without "/".
 */
export function isSafeSegment(value: unknown): value is string {
  return typeof value === "string" &&
    value.length > 0 &&
    value.trim() === value &&
    value !== "." &&
    value !== ".." &&
    !value.includes("/");
}

/**
 * Builds the cover folder of one uploader for one trip.
 *
 * @param {string} uid Uploader UID.
 * @param {string} tripId Trip identifier.
 * @return {string} Storage prefix ending with "/".
 */
export function coverPrefix(uid: string, tripId: string): string {
  return `users/${uid}/trips/${tripId}/cover/`;
}

/**
 * Computes the Storage files to delete when a trip is deleted.
 * Throws TripStoragePlanError for an invalid tripId or UID.
 * A coverPath that is not a cover of this very trip is ignored:
 * the owner can write any text there, so it is never trusted.
 *
 * @param {Object} input Trip data needed for the plan.
 * @return {TripStoragePlan} Prefixes and single files to delete.
 */
export function planTripStorageDeletion(input: {
  tripId: unknown;
  ownerUid: unknown;
  memberUids: unknown;
  coverPath: unknown;
}): TripStoragePlan {
  const {tripId, ownerUid} = input;

  if (!isSafeSegment(tripId)) {
    throw new TripStoragePlanError("Invalid tripId for Storage cleanup.");
  }

  if (!isSafeSegment(ownerUid)) {
    throw new TripStoragePlanError("Invalid ownerUid for Storage cleanup.");
  }

  const members = Array.isArray(input.memberUids) ? input.memberUids : [];
  const uids = new Set<string>([ownerUid]);

  for (const uid of members) {
    if (!isSafeSegment(uid)) {
      throw new TripStoragePlanError("Invalid member UID for Storage cleanup.");
    }
    uids.add(uid);
  }

  const prefixes = [...uids].map((uid) => coverPrefix(uid, tripId));
  const extraPaths: string[] = [];

  const coverPath = input.coverPath;
  if (typeof coverPath === "string" && coverPath.length > 0) {
    const parts = coverPath.split("/");
    const isCoverOfThisTrip = parts.length === 6 &&
      parts[0] === "users" &&
      isSafeSegment(parts[1]) &&
      parts[2] === "trips" &&
      parts[3] === tripId &&
      parts[4] === "cover" &&
      isSafeSegment(parts[5]);

    if (isCoverOfThisTrip &&
        !prefixes.some((prefix) => coverPath.startsWith(prefix))) {
      extraPaths.push(coverPath);
    }
  }

  return {prefixes, extraPaths};
}

/** Minimal part of a Storage bucket used here (easy to fake in tests). */
export type CoverBucket = {
  deleteFiles(options: {prefix: string}): Promise<unknown>;
  file(path: string): {
    delete(options: {ignoreNotFound: boolean}): Promise<unknown>;
  };
};

/**
 * Deletes every file of the plan. Missing files are fine; any other
 * error is thrown, so the caller can leave the trip untouched.
 *
 * @param {CoverBucket} bucket Storage bucket.
 * @param {TripStoragePlan} plan Files to delete.
 * @return {Promise<void>} Completion.
 */
export async function deleteTripStorage(
  bucket: CoverBucket,
  plan: TripStoragePlan,
): Promise<void> {
  for (const prefix of plan.prefixes) {
    await bucket.deleteFiles({prefix});
  }

  for (const path of plan.extraPaths) {
    await bucket.file(path).delete({ignoreNotFound: true});
  }
}
