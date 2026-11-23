// Test delle regole Firestore dei Ristoranti (trips/{tripId}/restaurants):
// controlli comuni delle sezioni più nome, stato, contatti, cucina,
// fascia di prezzo, prenotazione e voti (ognuno solo il proprio).

import {test} from 'node:test';

import {
  MEMBER,
  OTHER_MEMBER,
  assertFails,
  assertSucceeds,
  base,
  deleteField,
  sectionCommonTests,
  serverTimestamp,
  setDoc,
  setupSectionRules,
  updateDoc,
} from './section-rules-support.mjs';

setupSectionRules('demo-amaterasu-restaurants-rules');

function restaurant(uid, extra = {}) {
  return {...base(uid), name: 'Ippudo', status: 'toTry', ...extra};
}

const {ref, seed} = sectionCommonTests('restaurants', 'restaurants',
  restaurant, [
    {name: ''},
    {status: 'eaten'},
    {phone: 'chiama'},
    {website: 'ippudo.com'},
    {cuisine: 'x'.repeat(121)},
    {priceLevel: 5},
    {priceLevel: 2.5},
    {reservationDate: '14-04-2027'},
    {reservationTime: '7pm'},
    {partySize: 0},
    {partySize: 101},
    {votes: {[MEMBER]: 'Z'}},
    {votes: 'SS'},
  ], {status: 'tried', cuisine: 'Ramen'});

test('restaurants: every optional field and the own vote on create', async () => {
  await assertSucceeds(setDoc(ref(MEMBER, 'full'), restaurant(MEMBER, {
    status: 'booked',
    placeName: 'Ippudo Nishiki',
    placePlaceId: 'ChIJ-ippudo',
    placeLatitude: 35.0,
    placeLongitude: 135.7,
    phone: '+81 75 1234',
    website: 'https://ippudo.com',
    cuisine: 'Ramen',
    priceLevel: 2,
    reservationDate: '2027-04-14',
    reservationTime: '19:30',
    partySize: 4,
    notes: 'Coda lunga',
    votes: {[MEMBER]: 'SS'},
  })));
  await assertFails(setDoc(ref(MEMBER, 'other-vote'), restaurant(MEMBER, {
    votes: {[OTHER_MEMBER]: 'S'},
  })));
});

test('restaurants: each member changes only the own vote', async () => {
  await seed(MEMBER);
  await assertSucceeds(updateDoc(ref(OTHER_MEMBER), {
    [`votes.${OTHER_MEMBER}`]: 'S', updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(ref(MEMBER), {
    [`votes.${MEMBER}`]: 'A', updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ref(MEMBER), {
    [`votes.${OTHER_MEMBER}`]: 'B', updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(ref(OTHER_MEMBER), {
    [`votes.${OTHER_MEMBER}`]: deleteField(), updatedAt: serverTimestamp(),
  }));
  // An edit that keeps the votes is fine.
  await assertSucceeds(updateDoc(ref(OTHER_MEMBER), {
    cuisine: 'Tonkotsu', updatedAt: serverTimestamp(),
  }));
});
