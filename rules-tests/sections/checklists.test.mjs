// Test delle regole Firestore delle Checklist (trips/{tripId}/checklists):
// controlli comuni delle sezioni più titolo, visibilità, categorie, voci
// (al massimo 300, modificabili una alla volta) e liste personali.

import {test} from 'node:test';

import {
  MEMBER,
  OTHER_MEMBER,
  OWNER,
  TRIP,
  assertFails,
  assertSucceeds,
  base,
  deleteDoc,
  doc,
  env,
  getDoc,
  sectionCommonTests,
  serverTimestamp,
  setDoc,
  setupSectionRules,
  updateDoc,
} from './section-rules-support.mjs';

setupSectionRules('demo-amaterasu-checklists-rules');

function checklist(uid, extra = {}) {
  return {...base(uid), title: 'Valigia', visibility: 'shared', ...extra};
}

const items = (n) => Object.fromEntries(Array.from({length: n}, (_, i) => [
  `i${i}`, {text: `Voce ${i}`, category: 'Vestiti', done: false, order: i},
]));

const {ref} = sectionCommonTests('checklists', 'checklists', checklist, [
  {title: ''},
  {visibility: 'secret'},
  {categories: Array.from({length: 31}, (_, i) => `c${i}`)},
  {items: items(301)},
  {items: ['a']},
  {template: 'x'.repeat(41)},
], {title: 'Valigia di Anna'}, {wholeList: false});

test('checklists: categories, items and one-item updates', async () => {
  await assertSucceeds(setDoc(ref(MEMBER, 'full'), checklist(MEMBER, {
    template: 'packing',
    categories: ['Vestiti', 'Bagno'],
    items: items(300),
  })));
  await assertSucceeds(updateDoc(ref(OTHER_MEMBER, 'full'), {
    updatedByUid: OTHER_MEMBER,
    'items.i3.done': true, updatedAt: serverTimestamp(),
  }));
  // A list already has 300 items: one more is rejected.
  await assertFails(updateDoc(ref(OTHER_MEMBER, 'full'), {
    updatedByUid: OTHER_MEMBER,
    'items.extra': {text: 'Ombrello', category: 'Vestiti', done: false},
    updatedAt: serverTimestamp(),
  }));
});

test('checklists: a personal list is read only by its author', async () => {
  await env.testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'trips', TRIP, 'checklists', 'mine'), {
      ...checklist(MEMBER, {visibility: 'private'}),
      createdAt: new Date('2026-11-01T10:00:00Z'),
      updatedAt: new Date('2026-11-01T10:00:00Z'),
    });
  });
  await assertSucceeds(getDoc(ref(MEMBER, 'mine')));
  await assertFails(getDoc(ref(OTHER_MEMBER, 'mine')));
  await assertFails(getDoc(ref(OWNER, 'mine')));
  await assertFails(updateDoc(ref(OTHER_MEMBER, 'mine'), {
    updatedByUid: OTHER_MEMBER,
    title: 'x', updatedAt: serverTimestamp(),
  }));
  await assertFails(deleteDoc(ref(OWNER, 'mine')));
  await assertSucceeds(deleteDoc(ref(MEMBER, 'mine')));
});
