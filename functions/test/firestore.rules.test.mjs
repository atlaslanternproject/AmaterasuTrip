import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import { fileURLToPath } from 'node:url';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const rulesPath = fileURLToPath(
  new URL('../../firestore.rules', import.meta.url),
);

let testEnv;

function authenticatedDb(
  uid,
  {
    verified = true,
    email = `${uid}@example.com`,
  } = {},
) {
  return testEnv
    .authenticatedContext(uid, {
      email,
      email_verified: verified,
    })
    .firestore();
}

function tripData(ownerUid, memberUids = [ownerUid]) {
  return {
    name: 'Japan 2027',
    destination: 'Japan',
    destinationData: {
      placeId: 'test-place',
      displayName: 'Japan',
      formattedAddress: 'Japan',
      latitude: 35.6762,
      longitude: 139.6503,
    },
    startDate: new Date('2027-04-12T00:00:00Z'),
    endDate: new Date('2027-04-27T00:00:00Z'),
    currency: 'JPY',
    ownerUid,
    memberUids,
    status: 'active',
    createdAt: new Date(),
    updatedAt: new Date(),
  };
}

async function seedProfile(uid, username = uid) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'viaggiatori', uid), {
      username,
      usernameLower: username.toLowerCase(),
      email: `${uid}@example.com`,
      createdAt: new Date(),
    });

    await setDoc(doc(db, 'usernames', username.toLowerCase()), {
      uid,
      createdAt: new Date(),
    });
  });
}

async function seedTrip({
  tripId = 'trip-1',
  ownerUid = 'alice',
  memberUids = [ownerUid],
} = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(
      doc(db, 'trips', tripId),
      tripData(ownerUid, memberUids),
    );

    await setDoc(
      doc(db, 'trips', tripId, 'members', ownerUid),
      {
        uid: ownerUid,
        role: 'admin',
        joinedAt: new Date(),
        travellerProfileCompleted: true,
      },
    );

    for (const uid of memberUids) {
      if (uid === ownerUid) {
        continue;
      }

      await setDoc(
        doc(db, 'trips', tripId, 'members', uid),
        {
          uid,
          role: 'traveler',
          joinedAt: new Date(),
          travellerProfileCompleted: true,
        },
      );
    }
  });
}

async function createTripAs(db, uid, tripId = 'trip-created') {
  const batch = writeBatch(db);

  batch.set(
    doc(db, 'trips', tripId),
    {
      ...tripData(uid),
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    },
  );

  batch.set(
    doc(db, 'trips', tripId, 'members', uid),
    {
      uid,
      role: 'admin',
      joinedAt: serverTimestamp(),
      travellerProfileCompleted: true,
    },
  );

  return batch.commit();
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'amaterasutrip-rules-test',
    firestore: {
      rules: readFileSync(rulesPath, 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

test('anonymous client cannot read a private user profile', async () => {
  const db = testEnv.unauthenticatedContext().firestore();

  await assertFails(
    getDoc(doc(db, 'viaggiatori', 'alice')),
  );
});

test('authenticated user can read own profile', async () => {
  await seedProfile('alice');

  const db = authenticatedDb('alice');

  await assertSucceeds(
    getDoc(doc(db, 'viaggiatori', 'alice')),
  );
});

test('authenticated user cannot read another user profile', async () => {
  await seedProfile('bob');

  const db = authenticatedDb('alice');

  await assertFails(
    getDoc(doc(db, 'viaggiatori', 'bob')),
  );
});

test('username and matching profile can be created atomically', async () => {
  const db = authenticatedDb('alice', {
    verified: false,
    email: 'alice@example.com',
  });

  const batch = writeBatch(db);

  batch.set(doc(db, 'usernames', 'alice'), {
    uid: 'alice',
    createdAt: serverTimestamp(),
  });

  batch.set(doc(db, 'viaggiatori', 'alice'), {
    username: 'Alice',
    usernameLower: 'alice',
    email: 'alice@example.com',
    createdAt: serverTimestamp(),
  });

  await assertSucceeds(batch.commit());
});

test('orphan username index cannot be created', async () => {
  const db = authenticatedDb('alice', {
    verified: false,
  });

  await assertFails(
    setDoc(doc(db, 'usernames', 'alice'), {
      uid: 'alice',
      createdAt: serverTimestamp(),
    }),
  );
});

test('username can be changed atomically', async () => {
  await seedProfile('alice', 'alice');

  const db = authenticatedDb('alice');
  const batch = writeBatch(db);

  batch.set(doc(db, 'usernames', 'alice-new'), {
    uid: 'alice',
    createdAt: serverTimestamp(),
  });

  batch.delete(doc(db, 'usernames', 'alice'));

  batch.update(doc(db, 'viaggiatori', 'alice'), {
    username: 'Alice New',
    usernameLower: 'alice-new',
    updatedAt: serverTimestamp(),
  });

  await assertSucceeds(batch.commit());
});

test('username cannot change while old index remains reserved', async () => {
  await seedProfile('alice', 'alice');

  const db = authenticatedDb('alice');
  const batch = writeBatch(db);

  batch.set(doc(db, 'usernames', 'alice-new'), {
    uid: 'alice',
    createdAt: serverTimestamp(),
  });

  batch.update(doc(db, 'viaggiatori', 'alice'), {
    username: 'Alice New',
    usernameLower: 'alice-new',
    updatedAt: serverTimestamp(),
  });

  await assertFails(batch.commit());
});

test('username index still used by profile cannot be deleted alone', async () => {
  await seedProfile('alice', 'alice');

  const db = authenticatedDb('alice');

  await assertFails(
    deleteDoc(doc(db, 'usernames', 'alice')),
  );
});

test('verified user can create trip and owner member atomically', async () => {
  const db = authenticatedDb('alice', {
    verified: true,
  });

  await assertSucceeds(
    createTripAs(db, 'alice'),
  );
});

test('unverified user cannot create a trip', async () => {
  const db = authenticatedDb('alice', {
    verified: false,
  });

  await assertFails(
    createTripAs(db, 'alice'),
  );
});

test('trip member can read trip', async () => {
  await seedTrip({
    memberUids: ['alice', 'bob'],
  });

  const db = authenticatedDb('bob');

  await assertSucceeds(
    getDoc(doc(db, 'trips', 'trip-1')),
  );
});

test('non-member cannot read trip', async () => {
  await seedTrip();

  const db = authenticatedDb('mallory');

  await assertFails(
    getDoc(doc(db, 'trips', 'trip-1')),
  );
});

test('owner trip query used by repository is allowed', async () => {
  await seedTrip();

  const db = authenticatedDb('alice');

  const tripsQuery = query(
    collection(db, 'trips'),
    where('ownerUid', '==', 'alice'),
  );

  await assertSucceeds(getDocs(tripsQuery));
});

test('member trip query used by repository is allowed', async () => {
  await seedTrip({
    memberUids: ['alice', 'bob'],
  });

  const db = authenticatedDb('bob');

  const tripsQuery = query(
    collection(db, 'trips'),
    where('memberUids', 'array-contains', 'bob'),
  );

  await assertSucceeds(getDocs(tripsQuery));
});

test('broad trips collection query is denied', async () => {
  await seedTrip();

  const db = authenticatedDb('alice');

  await assertFails(
    getDocs(collection(db, 'trips')),
  );
});

test('owner can update allowed trip information', async () => {
  await seedTrip();

  const db = authenticatedDb('alice');

  await assertSucceeds(
    updateDoc(doc(db, 'trips', 'trip-1'), {
      name: 'Japan Updated',
      updatedAt: serverTimestamp(),
    }),
  );
});

test('owner cannot modify memberUids directly', async () => {
  await seedTrip();

  const db = authenticatedDb('alice');

  await assertFails(
    updateDoc(doc(db, 'trips', 'trip-1'), {
      memberUids: ['alice', 'mallory'],
      updatedAt: serverTimestamp(),
    }),
  );
});

test('traveler cannot update owner-only trip fields', async () => {
  await seedTrip({
    memberUids: ['alice', 'bob'],
  });

  const db = authenticatedDb('bob');

  await assertFails(
    updateDoc(doc(db, 'trips', 'trip-1'), {
      name: 'Hijacked trip',
      updatedAt: serverTimestamp(),
    }),
  );
});

test('client cannot create membership on an existing trip', async () => {
  await seedTrip();

  const db = authenticatedDb('bob');

  await assertFails(
    setDoc(doc(db, 'trips', 'trip-1', 'members', 'bob'), {
      uid: 'bob',
      role: 'traveler',
      joinedAt: serverTimestamp(),
      travellerProfileCompleted: true,
    }),
  );
});

test('trip members subcollection cannot be read directly', async () => {
  await seedTrip();

  const db = authenticatedDb('alice');

  await assertFails(
    getDoc(doc(db, 'trips', 'trip-1', 'members', 'alice')),
  );
});

test('trip invitation documents are inaccessible to clients', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), 'tripInvites', 'trip-1'),
      {
        tripId: 'trip-1',
        tokenHash: 'secret-hash',
        status: 'active',
      },
    );
  });

  const db = authenticatedDb('alice');

  await assertFails(
    getDoc(doc(db, 'tripInvites', 'trip-1')),
  );

  await assertFails(
    setDoc(doc(db, 'tripInvites', 'trip-2'), {
      tripId: 'trip-2',
      tokenHash: 'another-secret',
      status: 'active',
    }),
  );
});