// Test delle regole dell'Itinerario (itinerary, v1.63.0): le prove comuni
// delle sezioni (membri leggono, creazione e modifica firmate, dati non
// validi, elimina solo autore o proprietario) e quelle proprie: tipo,
// riferimento obbligatorio per "ref", ore, ordine, sezioni ammesse.

import {test} from 'node:test';

import {
  MEMBER,
  TRIP,
  assertFails,
  assertSucceeds,
  base,
  db,
  doc,
  sectionCommonTests,
  setDoc,
  setupSectionRules,
} from './section-rules-support.mjs';

setupSectionRules('demo-amaterasu-itinerary-rules');

const item = (uid, extra = {}) => ({
  ...base(uid),
  day: '2027-04-10',
  kind: 'free',
  title: 'Passeggiata a Gion',
  order: 0,
  ...extra,
});

sectionCommonTests('itinerary', 'itinerary', item, [
  {kind: 'auto'},
  {title: ''},
  {title: 'x'.repeat(201)},
  {day: '10/04/2027'},
  {time: '25:00'},
  {endTime: '9:00'},
  {order: -1},
  {order: 1.5},
  {kind: 'ref'},
  {kind: 'ref', refSection: 'notes', refId: 'a1'},
  {refId: 'bad/id'},
  {note: 'x'.repeat(2001)},
  {zone: 'x'.repeat(81)},
  {actualText: 'x'.repeat(501)},
  {placeLatitude: 120},
], {title: 'Cena a Pontocho', time: '19:30'});

test('itinerary: references, free days and "done instead"', async () => {
  const ref = (id) => doc(db(MEMBER), 'trips', TRIP, 'itinerary', id);
  await assertSucceeds(setDoc(ref('r1'), item(MEMBER, {
    kind: 'ref', refSection: 'restaurants', refId: 'k1', title: 'Gion Karyo',
    time: '19:00', endTime: '21:00', zone: 'Gion',
    placeName: 'Gion Karyo', placeLatitude: 35.0, placeLongitude: 135.77,
  })));
  await assertSucceeds(setDoc(ref('f1'), item(MEMBER, {
    kind: 'freeDay', title: 'Giornata libera',
  })));
  await assertSucceeds(setDoc(ref('a1'), item(MEMBER, {
    actualText: 'Pranzo al mercato', actualSection: 'savedPlaces',
    actualRefId: 'p1',
  })));
  await assertFails(setDoc(ref('a2'), item(MEMBER, {
    actualSection: 'budget', actualRefId: 'p1',
  })));
});
