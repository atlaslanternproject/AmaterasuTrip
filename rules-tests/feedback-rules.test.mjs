// Test delle regole della vecchia raccolta "feedback" (Extra F, fino alla
// 1.73.0): dalla 1.74.0 segnalazioni e idee partono per email, quindi
// nessuno può più scrivere; l'autore elenca e cancella solo le proprie
// vecchie segnalazioni (cancellazione dell'account), nessun altro le legge.

import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';
import {after, before, beforeEach, test} from 'node:test';
import {fileURLToPath} from 'node:url';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection, deleteDoc, doc, getDoc, getDocs, query, serverTimestamp, setDoc,
  where, writeBatch,
} from 'firebase/firestore';

const rulesPath = fileURLToPath(new URL('../firestore.rules', import.meta.url));
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-amaterasu-feedback',
    firestore: {rules: readFileSync(rulesPath, 'utf8')},
  });
});
beforeEach(async () => env.clearFirestore());
after(async () => env.cleanup());

const db = (uid) => env.authenticatedContext(uid).firestore();
const today = new Date().toISOString().slice(0, 10);
const item = (uid, extra = {}) => ({
  kind: 'bug', text: 'Il pulsante non risponde', appVersion: '1.47.0',
  language: 'it', createdByUid: uid, createdAt: serverTimestamp(), ...extra,
});

/** Old messages, written as the app did before 1.74.0. */
async function seed(entries) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    for (const [id, uid, extra] of entries) {
      await setDoc(doc(ctx.firestore(), 'feedback', id), item(uid, extra));
    }
  });
}

test('nobody can write new messages any more', async () => {
  await assertFails(setDoc(doc(db('alice'), 'feedback', `alice_${today}_1`), item('alice')));
  await assertFails(setDoc(doc(db('alice'), 'feedback', `alice_${today}_2`), item('alice', {kind: 'idea'})));
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), 'feedback', `x_${today}_1`), item('x')));
  await seed([[`alice_${today}_1`, 'alice']]);
  await assertFails(getDoc(doc(db('alice'), 'feedback', `alice_${today}_1`)));
  await assertFails(setDoc(doc(db('alice'), 'feedback', `alice_${today}_1`), item('alice', {text: 'nuovo'})));
});

test('the author lists and deletes own old messages, like account deletion', async () => {
  await seed([
    [`alice_${today}_1`, 'alice'],
    [`alice_${today}_2`, 'alice', {kind: 'idea'}],
    [`bob_${today}_1`, 'bob'],
  ]);
  const alice = db('alice');
  const own = query(collection(alice, 'feedback'), where('createdByUid', '==', 'alice'));
  const snap = await assertSucceeds(getDocs(own));
  assert.equal(snap.size, 2);
  // Others cannot list or delete them, and a query without the filter fails.
  await assertFails(getDocs(query(collection(db('bob'), 'feedback'), where('createdByUid', '==', 'alice'))));
  await assertFails(getDocs(collection(db('alice'), 'feedback')));
  await assertFails(deleteDoc(doc(db('bob'), 'feedback', `alice_${today}_1`)));
  // Same operation as the app: one batch deleting every own message.
  const batch = writeBatch(alice);
  for (const d of snap.docs) batch.delete(d.ref);
  await assertSucceeds(batch.commit());
  assert.equal((await getDocs(own)).size, 0);
});
