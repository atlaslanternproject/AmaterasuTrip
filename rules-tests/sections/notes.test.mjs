// Test delle regole Firestore delle Note (trips/{tripId}/notes): controlli
// comuni delle sezioni più titolo, visibilità, fissata, checklist e note
// private (le leggono, modificano ed eliminano solo i loro autori).

import {test} from 'node:test';

import {
  MEMBER,
  OTHER_MEMBER,
  OWNER,
  TRIP,
  assertFails,
  assertSucceeds,
  base,
  collection,
  db,
  deleteDoc,
  doc,
  env,
  getDoc,
  getDocs,
  sectionCommonTests,
  serverTimestamp,
  setDoc,
  setupSectionRules,
  updateDoc,
} from './section-rules-support.mjs';
import {query, where} from 'firebase/firestore';

setupSectionRules('demo-amaterasu-notes-rules');

function note(uid, extra = {}) {
  return {...base(uid), title: 'Wi-Fi', visibility: 'shared', ...extra};
}

const {ref} = sectionCommonTests('notes', 'notes', note, [
  {title: ''},
  {visibility: 'secret'},
  {body: 'x'.repeat(10001)},
  {pinned: 'yes'},
  {checklist: 'pane'},
  {checklist: Array.from({length: 101}, () => ({text: 'x', done: false}))},
  {linkSection: 'bucket', linkId: 's1', linkName: 'Hotel'},
  {linkSection: 'stays', linkId: 'a/b', linkName: 'Hotel'},
  {linkSection: 'stays', linkId: 's1', linkName: ''},
  {linkSection: 'stays', linkName: 'Hotel'},
], {pinned: true, body: 'Password: 1234'}, {wholeList: false});

async function seedPrivate(id = 'private-1') {
  await env.testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'trips', TRIP, 'notes', id), {
      ...note(MEMBER, {visibility: 'private', body: 'Solo mia'}),
      createdAt: new Date('2026-11-01T10:00:00Z'),
      updatedAt: new Date('2026-11-01T10:00:00Z'),
    });
  });
}

test('notes: linked to an element of another section', async () => {
  await assertSucceeds(setDoc(ref(MEMBER, 'linked'), note(MEMBER, {
    body: '# Check-in\n- Passaporti\n**Codice** 1234',
    linkSection: 'stays',
    linkId: 'stay_1',
    linkName: 'Ryokan Kyoto',
  })));
});

test('notes: checklist and pinned are saved', async () => {
  await assertSucceeds(setDoc(ref(MEMBER, 'list'), note(MEMBER, {
    pinned: true,
    checklist: [{text: 'Passaporto', done: true}, {text: 'Adattatore', done: false}],
  })));
});

test('notes: a private note is read only by its author', async () => {
  await seedPrivate();
  await assertSucceeds(getDoc(ref(MEMBER, 'private-1')));
  await assertFails(getDoc(ref(OTHER_MEMBER, 'private-1')));
  await assertFails(getDoc(ref(OWNER, 'private-1')));
  const notes = (uid) => collection(db(uid), 'trips', TRIP, 'notes');
  // The whole list is not readable; the app asks shared + own private.
  await assertFails(getDocs(notes(OTHER_MEMBER)));
  await assertSucceeds(getDocs(query(notes(OTHER_MEMBER),
    where('visibility', '==', 'shared'))));
  await assertSucceeds(getDocs(query(notes(OTHER_MEMBER),
    where('visibility', '==', 'private'),
    where('createdByUid', '==', OTHER_MEMBER))));
  await assertFails(getDocs(query(notes(OTHER_MEMBER),
    where('visibility', '==', 'private'))));
});

test('notes: only the author edits or deletes a private note', async () => {
  await seedPrivate();
  await assertFails(updateDoc(ref(OTHER_MEMBER, 'private-1'), {
    updatedByUid: OTHER_MEMBER,
    body: 'x', updatedAt: serverTimestamp(),
  }));
  await assertFails(deleteDoc(ref(OWNER, 'private-1')));
  await assertSucceeds(updateDoc(ref(MEMBER, 'private-1'), {
    updatedByUid: MEMBER,
    visibility: 'shared', updatedAt: serverTimestamp(),
  }));
  await seedPrivate('private-2');
  await assertSucceeds(deleteDoc(ref(MEMBER, 'private-2')));
});

test('notes: other members cannot make a shared note private', async () => {
  await assertSucceeds(setDoc(ref(MEMBER, 'shared'), note(MEMBER)));
  await assertFails(updateDoc(ref(OTHER_MEMBER, 'shared'), {
    updatedByUid: OTHER_MEMBER,
    visibility: 'private', updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(ref(OTHER_MEMBER, 'shared'), {
    updatedByUid: OTHER_MEMBER,
    checklist: [{text: 'Fatto', done: true}], updatedAt: serverTimestamp(),
  }));
});
