import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";

const db = getFirestore();

export const migrateOwnedTripsMembership = onCall(async (request) => {
  const uid = request.auth?.uid;

  if (uid == null) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication is required.",
    );
  }

  const tripsSnapshot = await db
    .collection("trips")
    .where("ownerUid", "==", uid)
    .get();

  let migratedTrips = 0;

  for (const tripSnapshot of tripsSnapshot.docs) {
    const tripRef = tripSnapshot.ref;
    const ownerMemberRef = tripRef.collection("members").doc(uid);
    const batch = db.batch();

    batch.update(tripRef, {
      memberUids: FieldValue.arrayUnion(uid),
    });

    batch.set(
      ownerMemberRef,
      {
        uid,
        role: "admin",
        joinedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    await batch.commit();
    migratedTrips++;
  }

  return {
    migratedTrips,
  };
});
