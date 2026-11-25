// Test delle regole dell'Audit Trail (v1.58.0): il registro
// trips/{tripId}/auditTrail lo leggono i membri; nessuno (nemmeno il
// proprietario) lo crea, lo modifica o lo cancella: lo scrive solo il
// server (recordTripAudit).

import {test} from 'node:test';

import {
  MEMBER,
  OUTSIDER,
  OWNER,
  TRIP,
  assertFails,
  assertSucceeds,
  collection,
  db,
  deleteDoc,
  doc,
  env,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  setupSectionRules,
  updateDoc,
} from './section-rules-support.mjs';

setupSectionRules('demo-amaterasu-audit-rules');

const entry = {
  at: new Date('2026-11-25T10:00:00Z'),
  actorUid: MEMBER,
  section: 'transports',
  itemId: 'item-1',
  itemName: 'Volo',
  action: 'update',
  changes: {number: {before: 'AZ1', after: 'AZ2'}},
};
const ref = (uid, id = 'e1') => doc(db(uid), 'trips', TRIP, 'auditTrail', id);

test('audit trail: members read, outsiders and anonymous users do not', async () => {
  await env.testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'trips', TRIP, 'auditTrail', 'e1'), entry);
  });
  await assertSucceeds(getDoc(ref(MEMBER)));
  await assertSucceeds(getDocs(collection(db(OWNER), 'trips', TRIP, 'auditTrail')));
  await assertFails(getDoc(ref(OUTSIDER)));
  await assertFails(getDoc(ref(null)));
});

test('audit trail: nobody writes, changes or deletes, not even the owner', async () => {
  await env.testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'trips', TRIP, 'auditTrail', 'e1'), entry);
  });
  await assertFails(setDoc(ref(MEMBER, 'new'), {...entry, at: serverTimestamp()}));
  await assertFails(setDoc(ref(OWNER, 'new'), {...entry, at: serverTimestamp()}));
  await assertFails(updateDoc(ref(OWNER), {itemName: 'Altro'}));
  await assertFails(deleteDoc(ref(OWNER)));
  await assertFails(deleteDoc(ref(MEMBER)));
});
