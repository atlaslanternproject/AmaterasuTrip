// Test delle regole Firestore di Hotel/Alloggi (trips/{tripId}/stays).
// Membri: leggono, creano e modificano; creatore o proprietario:
// cancellano; dati validati campo per campo; link come la bucket list;
// tipo di alloggio, telefono ed email facoltativi (v1.12.0).
// Uso: firebase emulators:exec --config firebase.emulators.security-test.json
//   --project demo-amaterasu-rules --only firestore
//   "node --test rules-tests/stays-rules.test.mjs"

import {readFileSync} from 'node:fs';
import {after, before, beforeEach, test} from 'node:test';
import {fileURLToPath} from 'node:url';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

import {
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const rulesPath = fileURLToPath(new URL('../firestore.rules', import.meta.url));
const TRIP = 'trip-1';
const OWNER = 'alice';
const MEMBER = 'bob';
const OTHER_MEMBER = 'carol';
const OUTSIDER = 'mallory';

let testEnv;

const db = (uid) => (uid ?
  testEnv.authenticatedContext(uid, {email_verified: true}) :
  testEnv.unauthenticatedContext()).firestore();

const stayRef = (uid, id = 'stay-1') => doc(db(uid), 'trips', TRIP, 'stays', id);

function stay(uid, extra = {}) {
  return {
    tripId: TRIP,
    name: 'Hotel Kyoto',
    checkInDate: '2027-04-12',
    checkOutDate: '2027-04-15',
    status: 'booked',
    createdByUid: uid,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...extra,
  };
}

/** Stored stay as already saved, written without rules. */
async function seedStay(createdByUid, id = 'stay-1') {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'trips', TRIP, 'stays', id), {
      ...stay(createdByUid),
      createdAt: new Date('2026-11-01T10:00:00Z'),
      updatedAt: new Date('2026-11-01T10:00:00Z'),
    });
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-amaterasu-stays-rules',
    firestore: {rules: readFileSync(rulesPath, 'utf8')},
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'trips', TRIP), {
      name: 'Japan',
      ownerUid: OWNER,
      memberUids: [OWNER, MEMBER, OTHER_MEMBER],
      status: 'active',
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

test('members read stays, outsiders and anonymous users do not', async () => {
  await seedStay(MEMBER);
  await assertSucceeds(getDoc(stayRef(OWNER)));
  await assertSucceeds(getDocs(collection(db(OTHER_MEMBER), 'trips', TRIP, 'stays')));
  await assertFails(getDoc(stayRef(OUTSIDER)));
  await assertFails(getDocs(collection(db(OUTSIDER), 'trips', TRIP, 'stays')));
  await assertFails(getDoc(stayRef(null)));
});

test('a member creates a minimal and a complete stay', async () => {
  await assertSucceeds(setDoc(stayRef(MEMBER), stay(MEMBER)));
  await assertSucceeds(setDoc(stayRef(OWNER, 'stay-2'), stay(OWNER, {
    checkInTime: '15:00',
    checkOutTime: '10:30',
    address: 'Shijo-dori 1',
    city: 'Kyoto',
    country: 'Japan',
    googlePlaceId: 'ChIJ-test',
    latitude: 35.0116,
    longitude: 135.7681,
    bookedVia: 'other',
    bookedViaOther: 'Expedia',
    bookingUrl: 'https://example.com/booking/123',
    propertyUrl: 'http://hotel.example.jp',
    confirmationCode: 'ABC123',
    notes: 'Colazione inclusa',
    guestUids: [OWNER, MEMBER],
    expenseId: 'expense_1-A',
    type: 'bnb',
    phone: '+39 06 1234 5678',
    email: 'info@hotel.example.jp',
  })));
});

test('type, phone and email: optional, typed and limited', async () => {
  const types = ['hotel', 'bnb', 'apartment', 'hostel', 'camping', 'other'];
  for (const [i, type] of types.entries()) {
    await assertSucceeds(setDoc(stayRef(MEMBER, `type-${i}`),
      stay(MEMBER, {type})));
  }
  for (const [i, phone] of ['(075) 123.456', '0612/34-56', '1'.repeat(40)]
    .entries()) {
    await assertSucceeds(setDoc(stayRef(MEMBER, `phone-${i}`),
      stay(MEMBER, {phone})));
  }
  await assertSucceeds(setDoc(stayRef(MEMBER, 'mail'),
    stay(MEMBER, {email: 'a.b@hotel.co.jp'})));

  const bad = [
    {type: 'villa'}, {type: 1}, {type: ''},
    {phone: '123'}, {phone: 'chiama'}, {phone: '+39 06 ext. 5'},
    {phone: '1'.repeat(41)}, {phone: 3906123456},
    {email: 'hotel.it'}, {email: 'a@b'}, {email: 'a b@c.it'},
    {email: 'a'.repeat(250) + '@b.it'}, {email: ['a@b.it']},
  ];
  for (const extra of bad) {
    await assertFails(setDoc(stayRef(MEMBER, 'bad'), stay(MEMBER, extra)));
  }

  // Editing adds and removes the new fields like the others.
  await seedStay(MEMBER, 'edit');
  await assertSucceeds(updateDoc(stayRef(OTHER_MEMBER, 'edit'), {
    type: 'hostel', phone: '+81 75 1234', email: 'x@y.jp',
    updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(stayRef(OTHER_MEMBER, 'edit'), {
    type: deleteField(), phone: deleteField(), email: deleteField(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(stayRef(OTHER_MEMBER, 'edit'), {
    email: 'nope', updatedAt: serverTimestamp(),
  }));
});

test('outsiders cannot create, and nobody can create for someone else', async () => {
  await assertFails(setDoc(stayRef(OUTSIDER), stay(OUTSIDER)));
  await assertFails(setDoc(stayRef(null), stay('anyone')));
  await assertFails(setDoc(stayRef(MEMBER), stay(OWNER)));
});

test('invalid data is rejected', async () => {
  const bad = [
    {extraField: true},
    {tripId: 'other-trip'},
    {name: ''},
    {name: 'x'.repeat(201)},
    {checkInDate: '12/04/2027'},
    {checkOutDate: '2027-04-11'},
    {status: 'maybe'},
    {checkInTime: '25:00'},
    {checkOutTime: '9:00'},
    {bookedVia: 'expedia'},
    {bookedViaOther: 'Expedia'},
    {bookedVia: 'other', bookedViaOther: ''},
    {bookedVia: 'other', bookedViaOther: 'x'.repeat(61)},
    {bookingUrl: 'ftp://example.com'},
    {propertyUrl: 'example.com'},
    {bookingUrl: 'https://example.com/a b'},
    {bookingUrl: 'https://example.com/' + 'x'.repeat(2048)},
    {confirmationCode: 'x'.repeat(101)},
    {notes: 'x'.repeat(10001)},
    {latitude: 91},
    {longitude: -181},
    {guestUids: 'bob'},
    {guestUids: Array.from({length: 51}, (_, i) => `u${i}`)},
    {expenseId: 'bad/id'},
    {updatedAt: new Date('2020-01-01T00:00:00Z')},
  ];
  for (const extra of bad) {
    await assertFails(setDoc(stayRef(MEMBER), stay(MEMBER, extra)));
  }
  await assertFails(setDoc(stayRef(MEMBER), {
    ...stay(MEMBER), createdAt: new Date('2020-01-01T00:00:00Z'),
  }));
});

test('any member edits a stay, keeping author and creation time', async () => {
  await seedStay(MEMBER);
  await assertSucceeds(updateDoc(stayRef(OTHER_MEMBER), {
    name: 'Hotel Kyoto Station',
    status: 'toConfirm',
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(stayRef(OTHER_MEMBER), {
    createdByUid: OTHER_MEMBER, updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(stayRef(OTHER_MEMBER), {
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(stayRef(OTHER_MEMBER), {name: 'No time'}));
  await assertFails(updateDoc(stayRef(OUTSIDER), {
    name: 'Hacked', updatedAt: serverTimestamp(),
  }));
});

test('the creator or the owner deletes; other members and outsiders do not', async () => {
  await seedStay(MEMBER, 'by-member');
  await seedStay(MEMBER, 'by-member-2');
  await assertFails(deleteDoc(stayRef(OTHER_MEMBER, 'by-member')));
  await assertFails(deleteDoc(stayRef(OUTSIDER, 'by-member')));
  await assertSucceeds(deleteDoc(stayRef(MEMBER, 'by-member')));
  await assertSucceeds(deleteDoc(stayRef(OWNER, 'by-member-2')));
});

test('a former member loses access to the stays', async () => {
  await seedStay(MEMBER);
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), 'trips', TRIP), {
      memberUids: [OWNER, OTHER_MEMBER],
    });
  });
  await assertFails(getDoc(stayRef(MEMBER)));
  await assertFails(deleteDoc(stayRef(MEMBER)));
});
