// Funzione "recordTripAudit" (Audit Trail, v1.58.0): a ogni scrittura in
// una sezione nuova aggiunge una voce in trips/{tripId}/auditTrail (chi,
// cosa, quando con l'ora del server, prima/dopo). Ignora documenti privati,
// scritture del server (eliminazione o copia del viaggio) e modifiche
// senza cambiamenti. Il registro non si modifica né si cancella dall'app.

import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {onDocumentWrittenWithAuthContext} from
  "firebase-functions/v2/firestore";

import {
  auditAction, auditChanges, auditItemName, auditSections, isPrivate,
} from "./audit-changes";

const db = getFirestore();

export const recordTripAudit = onDocumentWrittenWithAuthContext(
  {document: "trips/{tripId}/{section}/{itemId}", region: "europe-west1"},
  async (event) => {
    const {tripId, section, itemId} = event.params;
    if (!auditSections.has(section)) return;
    // Server writes (deleteTrip, duplicateTrip) are not user changes.
    if (event.authType === "service_account" || event.authType === "system") {
      return;
    }
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (isPrivate(before) || isPrivate(after)) return;
    const action = auditAction(before !== undefined, after !== undefined);
    const changes = auditChanges(before, after);
    if (action === "update" && Object.keys(changes).length === 0) return;
    // The writer signs every change (rules); a deletion is signed just
    // before it by the app, so the last signature is who deleted.
    const actorUid = after?.updatedByUid ?? before?.updatedByUid ??
      before?.createdByUid ?? null;
    const tripRef = db.collection("trips").doc(tripId);
    const trip = await tripRef.get();
    if (!trip.exists) return;
    await tripRef.collection("auditTrail").add({
      at: FieldValue.serverTimestamp(),
      actorUid: typeof actorUid === "string" ? actorUid : null,
      section,
      itemId,
      itemName: auditItemName(after ?? before),
      action,
      changes: action === "update" ? changes : {},
    });
  },
);
