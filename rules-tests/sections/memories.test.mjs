// Test delle regole Firestore dei Ricordi (trips/{tripId}/memories):
// controlli comuni delle sezioni più diario (data obbligatoria,
// valutazione 1-5, momento del giorno) e album (nome e link obbligatori).

import {test} from 'node:test';

import {
  MEMBER,
  assertFails,
  assertSucceeds,
  base,
  sectionCommonTests,
  setDoc,
  setupSectionRules,
} from './section-rules-support.mjs';

setupSectionRules('demo-amaterasu-memories-rules');

function day(uid, extra = {}) {
  return {...base(uid), kind: 'day', date: '2027-04-12', ...extra};
}

const {ref} = sectionCommonTests('memories', 'memories', day, [
  {kind: 'photo'},
  {date: null},
  {date: '12 aprile'},
  {rating: 0},
  {rating: 6},
  {moment: 'x'.repeat(301)},
  {text: 'x'.repeat(10001)},
  {url: 'photos.google.com'},
], {text: 'Giornata a Nara', rating: 5});

test('memories: diary page and album link', async () => {
  await assertSucceeds(setDoc(ref(MEMBER, 'day'), day(MEMBER, {
    text: 'Cervi ovunque', rating: 4, moment: 'Il tramonto al tempio',
  })));
  await assertSucceeds(setDoc(ref(MEMBER, 'album'), {
    ...base(MEMBER),
    kind: 'album',
    title: 'Foto di Kyoto',
    url: 'https://photos.app.goo.gl/abc',
  }));
  await assertFails(setDoc(ref(MEMBER, 'album-no-link'), {
    ...base(MEMBER), kind: 'album', title: 'Foto',
  }));
});
