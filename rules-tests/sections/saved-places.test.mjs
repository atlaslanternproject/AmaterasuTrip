// Test delle regole Firestore dei Luoghi salvati
// (trips/{tripId}/savedPlaces): controlli comuni delle sezioni più nome,
// categoria, luogo, link di Google Maps, note, priorità, visitato, tempo
// di visita, link dei biglietti, zona, giorno e prezzo d'ingresso.

import {test} from 'node:test';

import {
  MEMBER,
  assertSucceeds,
  base,
  sectionCommonTests,
  setDoc,
  setupSectionRules,
} from './section-rules-support.mjs';

setupSectionRules('demo-amaterasu-saved-places-rules');

function savedPlace(uid, extra = {}) {
  return {...base(uid), name: 'Fushimi Inari', category: 'sight', ...extra};
}

const {ref} = sectionCommonTests('savedPlaces', 'savedPlaces', savedPlace, [
  {name: ''},
  {category: 'museum'},
  {placeLongitude: 200},
  {mapsUrl: 'maps.google.com'},
  {notes: 'x'.repeat(10001)},
  {phone: 'chiama'},
  {website: 'inari.jp'},
  {priority: 'SSS'},
  {visited: 'sì'},
  {visitMinutes: 0},
  {visitMinutes: 1441},
  {ticketsUrl: 'biglietti'},
  {area: 'x'.repeat(121)},
  {plannedDay: '12/04'},
], {category: 'nature', notes: 'All\'alba'});

test('savedPlaces: Google place or pasted Maps link', async () => {
  await assertSucceeds(setDoc(ref(MEMBER, 'google'), savedPlace(MEMBER, {
    placeName: 'Fushimi Inari Taisha',
    placeAddress: 'Kyoto',
    placePlaceId: 'ChIJ-inari',
    placeLatitude: 34.96,
    placeLongitude: 135.77,
    phone: '+81 75 641 7331',
    website: 'https://inari.jp',
    priority: 'SS',
    visited: true,
    visitMinutes: 120,
    ticketsUrl: 'https://inari.jp/tickets',
    area: 'Higashiyama',
    plannedDay: '2027-04-14',
    estimatedCostMinorUnits: 500,
    estimatedCostCurrency: 'JPY',
  })));
  await assertSucceeds(setDoc(ref(MEMBER, 'link'), savedPlace(MEMBER, {
    mapsUrl: 'https://maps.app.goo.gl/abc123',
    notes: 'Consigliato da Bruno',
  })));
});
