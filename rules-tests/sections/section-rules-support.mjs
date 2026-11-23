// Supporto comune ai test delle regole delle sezioni del viaggio
// (trasporti, prenotazioni, ristoranti...): viaggio di prova con
// proprietario e membri, e i controlli uguali per tutte le sezioni
// (lettura, creazione, modifica, eliminazione, costo e spesa collegata).

import {readFileSync} from 'node:fs';
import {after, before, beforeEach, test} from 'node:test';
import {fileURLToPath} from 'node:url';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

import {
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

export {assertFails, assertSucceeds, deleteField, doc, getDoc, getDocs,
  collection, serverTimestamp, setDoc, updateDoc, deleteDoc};

const rulesPath = fileURLToPath(
  new URL('../../firestore.rules', import.meta.url),
);
export const TRIP = 'trip-1';
export const OWNER = 'alice';
export const MEMBER = 'bob';
export const OTHER_MEMBER = 'carol';
export const OUTSIDER = 'mallory';

export const env = {testEnv: null};

export const db = (uid) => (uid ?
  env.testEnv.authenticatedContext(uid, {email_verified: true}) :
  env.testEnv.unauthenticatedContext()).firestore();

/** Registers the emulator setup for a test file. */
export function setupSectionRules(projectId) {
  before(async () => {
    env.testEnv = await initializeTestEnvironment({
      projectId,
      firestore: {rules: readFileSync(rulesPath, 'utf8')},
    });
  });
  beforeEach(async () => {
    await env.testEnv.clearFirestore();
    await env.testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'trips', TRIP), {
        name: 'Japan',
        ownerUid: OWNER,
        memberUids: [OWNER, MEMBER, OTHER_MEMBER],
        status: 'active',
      });
    });
  });
  after(async () => {
    await env.testEnv?.cleanup();
  });
}

/**
 * The tests every section shares. [item](uid, extra) is a valid new
 * document; [bad] lists invalid extra fields; [edit] is a valid change.
 */
export function sectionCommonTests(name, path, item, bad, edit) {
  const ref = (uid, id = 'item-1') =>
    doc(db(uid), 'trips', TRIP, path, id);

  async function seed(createdByUid, id = 'item-1') {
    await env.testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'trips', TRIP, path, id), {
        ...item(createdByUid),
        createdAt: new Date('2026-11-01T10:00:00Z'),
        updatedAt: new Date('2026-11-01T10:00:00Z'),
      });
    });
  }

  test(`${name}: members read, outsiders and anonymous users do not`, async () => {
    await seed(MEMBER);
    await assertSucceeds(getDoc(ref(OTHER_MEMBER)));
    await assertSucceeds(getDocs(collection(db(OWNER), 'trips', TRIP, path)));
    await assertFails(getDoc(ref(OUTSIDER)));
    await assertFails(getDoc(ref(null)));
  });

  test(`${name}: a member creates; nobody creates for someone else`, async () => {
    await assertSucceeds(setDoc(ref(MEMBER), item(MEMBER)));
    await assertSucceeds(setDoc(ref(MEMBER, 'with-cost'), item(MEMBER, {
      estimatedCostMinorUnits: 4500,
      estimatedCostCurrency: 'EUR',
      expenseId: 'exp_1',
    })));
    await assertFails(setDoc(ref(MEMBER, 'other'), item(OTHER_MEMBER)));
    await assertFails(setDoc(ref(OUTSIDER, 'out'), item(OUTSIDER)));
  });

  test(`${name}: invalid data is rejected`, async () => {
    const common = [
      {unknownField: 1},
      {tripId: 'other-trip'},
      {estimatedCostMinorUnits: 100},
      {estimatedCostMinorUnits: 0, estimatedCostCurrency: 'EUR'},
      {estimatedCostMinorUnits: 100, estimatedCostCurrency: 'euro'},
      {expenseId: 'bad/id'},
      {updatedAt: new Date('2020-01-01T00:00:00Z')},
    ];
    for (const extra of [...common, ...bad]) {
      await assertFails(setDoc(ref(MEMBER, 'bad'), item(MEMBER, extra)),
        JSON.stringify(extra));
    }
  });

  test(`${name}: any member edits, keeping author and creation time`, async () => {
    await seed(MEMBER);
    await assertSucceeds(updateDoc(ref(OTHER_MEMBER), {
      ...edit, updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(ref(OTHER_MEMBER), {
      createdByUid: OTHER_MEMBER, updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(ref(OTHER_MEMBER), {
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(ref(OUTSIDER), {
      ...edit, updatedAt: serverTimestamp(),
    }));
  });

  test(`${name}: the creator or the owner deletes; others do not`, async () => {
    await seed(MEMBER, 'a');
    await seed(MEMBER, 'b');
    await assertFails(deleteDoc(ref(OTHER_MEMBER, 'a')));
    await assertFails(deleteDoc(ref(OUTSIDER, 'a')));
    await assertSucceeds(deleteDoc(ref(MEMBER, 'a')));
    await assertSucceeds(deleteDoc(ref(OWNER, 'b')));
  });

  return {ref, seed};
}

/** Base fields every section document has. */
export function base(uid) {
  return {
    tripId: TRIP,
    createdByUid: uid,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}
