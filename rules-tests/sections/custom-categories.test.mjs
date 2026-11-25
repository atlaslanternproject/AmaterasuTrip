// Test delle regole delle categorie personalizzate (Extra D): raccolta
// trips/{tripId}/sectionCategories (solo membri, solo creazione, come
// bucketCategories) e campo customCategories nelle sezioni (fino a 5
// etichette di 1-60 caratteri).

import {test} from 'node:test';

import {
  MEMBER,
  OUTSIDER,
  TRIP,
  assertFails,
  assertSucceeds,
  base,
  db,
  doc,
  serverTimestamp,
  setDoc,
  setupSectionRules,
  updateDoc,
} from './section-rules-support.mjs';

setupSectionRules('demo-amaterasu-categories-rules');

const category = (uid, id) => doc(db(uid), 'trips', TRIP, 'sectionCategories', id);
const label = (uid, text = 'Da non perdere') => ({
  label: text, createdByUid: uid, createdAt: serverTimestamp(),
});

test('trip categories: members create, nobody changes or deletes', async () => {
  await assertSucceeds(setDoc(category(MEMBER, 'da-non-perdere'), label(MEMBER)));
  await assertFails(setDoc(category(OUTSIDER, 'altro'), label(OUTSIDER)));
  await assertFails(setDoc(category(MEMBER, 'Maiuscole'), label(MEMBER)));
  await assertFails(setDoc(category(MEMBER, 'lunga'), label(MEMBER, 'x'.repeat(61))));
  await assertFails(setDoc(category(MEMBER, 'vuota'), label(MEMBER, '')));
  await assertFails(updateDoc(category(MEMBER, 'da-non-perdere'), {label: 'Altro'}));
});

const required = {
  reservations: {name: 'Museo', category: 'ticket', status: 'toBook'},
  restaurants: {name: 'Ichiran', status: 'toTry'},
  savedPlaces: {name: 'Inari', category: 'sight'},
  notes: {title: 'Idee', visibility: 'shared'},
  shoppingItems: {name: 'Tè', bought: false},
};
for (const [coll, data] of Object.entries(required)) {
  test(`${coll}: custom categories are optional and checked`, async () => {
    const ref = (id) => doc(db(MEMBER), 'trips', TRIP, coll, id);
    const item = (extra) => ({...base(MEMBER), ...data, ...extra});
    await assertSucceeds(setDoc(ref('ok'), item({
      customCategories: ['Romantico', 'Da non perdere', 'C3', 'C4', 'C5'],
    })));
    for (const bad of [
      'Romantico', [], ['a', 'b', 'c', 'd', 'e', 'f'], ['x'.repeat(61)],
      [''], ['con | barra'], [5],
    ]) {
      await assertFails(setDoc(ref('bad'), item({customCategories: bad})));
    }
  });
}
