// Test delle regole di "Segnala un problema / Suggerisci un'idea"
// (feedback, Extra F): al massimo 5 al giorno per utente (id
// uid_giorno_1..5 con il giorno del server), nessuna modifica, campi
// controllati; l'autore elenca e cancella solo i propri (cancellazione
// dell'account), nessun altro li legge.

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

test('up to 5 a day, no overwrite, nobody reads', async () => {
  for (let n = 1; n <= 5; n++) {
    await assertSucceeds(setDoc(doc(db('alice'), 'feedback', `alice_${today}_${n}`), item('alice')));
  }
  await assertFails(setDoc(doc(db('alice'), 'feedback', `alice_${today}_6`), item('alice')));
  await assertFails(setDoc(doc(db('alice'), 'feedback', `alice_${today}_1`), item('alice')));
  await assertFails(getDoc(doc(db('alice'), 'feedback', `alice_${today}_1`)));
});

test('wrong day, other user, bad fields are refused', async () => {
  await assertFails(setDoc(doc(db('alice'), 'feedback', `alice_2000-01-01_1`), item('alice')));
  await assertFails(setDoc(doc(db('alice'), 'feedback', `bob_${today}_1`), item('alice')));
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), 'feedback', `x_${today}_1`), item('x')));
  for (const bad of [
    {kind: 'spam'}, {text: ''}, {text: 'x'.repeat(2001)}, {appVersion: 'v1'},
    {language: 'fr'}, {createdByUid: 'bob'}, {email: 'a@b.it'},
  ]) {
    await assertFails(setDoc(doc(db('alice'), 'feedback', `alice_${today}_2`), item('alice', bad)));
  }
  await assertSucceeds(setDoc(doc(db('alice'), 'feedback', `alice_${today}_2`), item('alice', {kind: 'idea'})));
});

test('the author lists and deletes own messages, like account deletion', async () => {
  await setDoc(doc(db('alice'), 'feedback', `alice_${today}_1`), item('alice'));
  await setDoc(doc(db('alice'), 'feedback', `alice_${today}_2`), item('alice', {kind: 'idea'}));
  await setDoc(doc(db('bob'), 'feedback', `bob_${today}_1`), item('bob'));
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
