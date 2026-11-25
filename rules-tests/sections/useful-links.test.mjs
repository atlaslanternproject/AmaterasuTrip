// Test delle regole dei "Link utili" (usefulLinks) nelle sezioni nuove:
// fino a 10 indirizzi http(s) senza spazi, controllati con un solo
// confronto (sectionLinks); un trasporto con tutti i campi e 10 link resta
// sotto il limite di 1000 operazioni di Firestore.

import {test} from 'node:test';

import {
  MEMBER,
  TRIP,
  assertFails,
  assertSucceeds,
  base,
  db,
  doc,
  setDoc,
  setupSectionRules,
} from './section-rules-support.mjs';

setupSectionRules('demo-amaterasu-useful-links-rules');

const required = {
  transports: {type: 'train', status: 'booked', departureDate: '2027-04-12'},
  reservations: {name: 'Museo', category: 'ticket', status: 'toBook'},
  restaurants: {name: 'Ichiran', status: 'toTry'},
  savedPlaces: {name: 'Inari', category: 'sight'},
  notes: {title: 'Wi-Fi', visibility: 'shared'},
  shoppingItems: {name: 'Tè', bought: false},
  memories: {kind: 'day', date: '2027-04-12'},
};
const ten = Array.from({length: 10}, (_, i) => `https://example.com/${i}`);
const ref = (coll, id) => doc(db(MEMBER), 'trips', TRIP, coll, id);
const item = (coll, extra) => ({...base(MEMBER), ...required[coll], ...extra});

for (const coll of Object.keys(required)) {
  test(`${coll}: useful links are optional and checked`, async () => {
    await assertSucceeds(setDoc(ref(coll, 'one'), item(coll, {
      usefulLinks: ['http://a.it'],
    })));
    await assertSucceeds(setDoc(ref(coll, 'ten'), item(coll, {usefulLinks: ten})));
    for (const bad of [
      'https://a.it',
      [],
      [...ten, 'https://example.com/11'],
      ['www.a.it'],
      ['https://a.it/con spazio'],
      ['https://a.it', 5],
      ['https://' + 'x'.repeat(20500)],
    ]) {
      await assertFails(setDoc(ref(coll, 'bad'), item(coll, {usefulLinks: bad})));
    }
  });
}

test('transports: every optional field and 10 links together', async () => {
  await assertSucceeds(setDoc(ref('transports', 'full'), item('transports', {
    type: 'flight',
    fromName: 'Roma Fiumicino', fromAddress: 'Fiumicino RM',
    fromPlaceId: 'ChIJ-fco', fromLatitude: 41.8, fromLongitude: 12.2,
    toName: 'Tokyo Haneda', toPlaceId: 'ChIJ-hnd',
    toLatitude: 35.5, toLongitude: 139.7,
    departureTime: '13:05', departureOffset: '+01:00',
    arrivalDate: '2027-04-13', arrivalTime: '09:40', arrivalOffset: '+09:00',
    carrier: 'ITA Airways', number: 'AZ 792', bookingCode: 'ABC123',
    seats: '23A, 23B', passengerUids: [MEMBER],
    bookedVia: 'Sito della compagnia', bookingUrl: 'https://www.ita.com',
    notes: 'Bagaglio in stiva',
    estimatedCostMinorUnits: 90000, estimatedCostCurrency: 'EUR',
    expenseId: 'e1',
    extras: {
      seatsByPassenger: {[MEMBER]: {letter: 'C', seat: '23A'}},
      checkInHoursBefore: 24, checkInUrl: 'https://www.ita.com/check-in',
      airportMinutesBefore: 120, fuelPolicy: 'Pieno-pieno',
      deductible: '800 EUR',
    },
    usefulLinks: ten,
  })));
});
