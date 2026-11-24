// Test delle regole Firestore dei Trasporti (trips/{tripId}/transports):
// controlli comuni delle sezioni più tipo, stato, date, orari, fusi
// orari, luoghi, passeggeri e link.
// Uso: firebase emulators:exec --config firebase.emulators.security-test.json
//   --project demo-amaterasu-rules --only firestore
//   "node --test rules-tests/sections/transports.test.mjs"

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

setupSectionRules('demo-amaterasu-transports-rules');

function transport(uid, extra = {}) {
  return {
    ...base(uid),
    type: 'train',
    status: 'booked',
    departureDate: '2027-04-12',
    ...extra,
  };
}

const {ref} = sectionCommonTests('transports', 'transports', transport, [
  {type: 'rocket'},
  {status: 'done'},
  {departureDate: '12/04/2027'},
  {arrivalDate: '2027-04-11'},
  {departureTime: '25:00'},
  {departureOffset: '+15:00'},
  {arrivalOffset: '01:00'},
  {fromLatitude: 91},
  {toName: 'x'.repeat(201)},
  {carrier: 'x'.repeat(121)},
  {carrier: ['ITA']},
  {notes: 5},
  {bookingCode: 'x'.repeat(101)},
  {passengerUids: Array.from({length: 51}, (_, i) => `u${i}`)},
  {bookingUrl: 'javascript:alert(1)'},
  {notes: 'x'.repeat(10001)},
  {extras: 'x'},
  {extras: {seatsByPassenger: 'A12'}},
  {extras: {checkInHoursBefore: 200}},
  {extras: {checkInHoursBefore: 2.5}},
  {extras: {checkInUrl: 'check-in'}},
  {extras: {airportMinutesBefore: 700}},
  {extras: {fuelPolicy: 'x'.repeat(61)}},
  {extras: {other: 1}},
], {status: 'cancelled', carrier: 'Trenitalia'});

test('transports: a complete trip with every optional field', async () => {
  await assertSucceeds(setDoc(ref(MEMBER, 'full'), transport(MEMBER, {
    type: 'flight',
    fromName: 'Roma Fiumicino',
    fromAddress: 'Fiumicino RM',
    fromPlaceId: 'ChIJ-fco',
    fromLatitude: 41.8,
    fromLongitude: 12.2,
    toName: 'Tokyo Haneda',
    toPlaceId: 'ChIJ-hnd',
    toLatitude: 35.5,
    toLongitude: 139.7,
    departureTime: '13:05',
    departureOffset: '+01:00',
    arrivalDate: '2027-04-13',
    arrivalTime: '09:40',
    arrivalOffset: '+09:00',
    carrier: 'ITA Airways',
    number: 'AZ 792',
    bookingCode: 'ABC123',
    seats: '23A, 23B',
    passengerUids: [MEMBER],
    bookedVia: 'Sito della compagnia',
    bookingUrl: 'https://www.ita-airways.com',
    notes: 'Bagaglio in stiva',
    extras: {
      seatsByPassenger: {[MEMBER]: {letter: 'C', seat: '23A'}},
      checkInHoursBefore: 24,
      checkInUrl: 'https://www.ita-airways.com/check-in',
      airportMinutesBefore: 120,
      fuelPolicy: 'Pieno-pieno',
      deductible: '800 EUR',
    },
  })));
  await assertSucceeds(setDoc(ref(MEMBER, 'half-hour'), transport(MEMBER, {
    departureOffset: '+05:30', arrivalOffset: '-03:30',
  })));
  await assertFails(setDoc(ref(MEMBER, 'no-type'), (() => {
    const data = transport(MEMBER);
    delete data.type;
    return data;
  })()));
});
