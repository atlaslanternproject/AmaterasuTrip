// Test delle regole di "Segnala un problema / Suggerisci un'idea"
// (feedback, Extra F): solo creazione, al massimo 5 al giorno per utente
// (id uid_giorno_1..5 con il giorno del server), nessuna lettura né
// modifica dall'app, campi controllati.

import {readFileSync} from 'node:fs';
import {after, before, beforeEach, test} from 'node:test';
import {fileURLToPath} from 'node:url';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {doc, getDoc, serverTimestamp, setDoc} from 'firebase/firestore';

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
