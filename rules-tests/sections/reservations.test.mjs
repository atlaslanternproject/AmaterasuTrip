// Test delle regole Firestore delle Prenotazioni
// (trips/{tripId}/reservations): controlli comuni delle sezioni più nome,
// categoria, stato, data, ora, luogo, partecipanti e cancellazione.

import {test} from 'node:test';

import {
  MEMBER,
  assertSucceeds,
  base,
  sectionCommonTests,
  setDoc,
  setupSectionRules,
} from './section-rules-support.mjs';

setupSectionRules('demo-amaterasu-reservations-rules');

function reservation(uid, extra = {}) {
  return {
    ...base(uid),
    name: 'Museo Ghibli',
    category: 'entry',
    status: 'toBook',
    ...extra,
  };
}

const {ref} = sectionCommonTests('reservations', 'reservations', reservation, [
  {name: ''},
  {name: 'x'.repeat(201)},
  {category: 'concert'},
  {status: 'done'},
  {date: '2027/04/12'},
  {time: '9:00'},
  {placeLatitude: 100},
  {placeName: 'x'.repeat(201)},
  {bookingCode: 'x'.repeat(101)},
  {bookingUrl: 'www.example.com'},
  {participantUids: 'anna'},
  {cancellationPolicy: 'x'.repeat(2001)},
], {status: 'booked', bookingCode: 'GHB-1'});

test('reservations: every optional field', async () => {
  await assertSucceeds(setDoc(ref(MEMBER, 'full'), reservation(MEMBER, {
    category: 'tour',
    status: 'booked',
    date: '2027-04-14',
    time: '10:00',
    placeName: 'Museo Ghibli',
    placeAddress: 'Mitaka, Tokyo',
    placePlaceId: 'ChIJ-ghibli',
    placeLatitude: 35.69,
    placeLongitude: 139.57,
    bookingCode: 'GHB-1',
    bookingUrl: 'https://www.ghibli-museum.jp',
    participantUids: [MEMBER],
    cancellationPolicy: 'Non rimborsabile',
    notes: 'Arrivare 15 minuti prima',
  })));
});
