// Test delle regole di Firebase Storage (storage.rules) con l'emulatore.
// Copre foto profilo e copertine dei viaggi: lettura solo da utenti
// autenticati, scrittura e cancellazione solo del proprietario, limite di
// 5 MB, solo immagini, ogni altro percorso negato.
// Uso: firebase emulators:exec --config firebase.emulators.security-test.json
//   --project demo-amaterasu-storage --only storage
//   "node --test rules-tests/storage-rules.test.cjs"

"use strict";

const test = require("node:test");
const {after, before, beforeEach} = require("node:test");
const fs = require("node:fs");
const path = require("node:path");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");

const projectId = "demo-amaterasu-storage";
const OWNER = "anna";
const OTHER = "bruno";
const MB = 1024 * 1024;

const profilePath = (uid, name = "profile_1.jpg") =>
  `users/${uid}/profile/${name}`;
const coverPath = (uid, name = "cover_1.jpg") =>
  `users/${uid}/trips/trip-1/cover/${name}`;

let testEnv;

function bytes(size) {
  return new Uint8Array(size).fill(7);
}

function storageAs(uid) {
  const context = uid ?
    testEnv.authenticatedContext(uid) :
    testEnv.unauthenticatedContext();
  return context.storage();
}

/** Carica un file ignorando le regole, per preparare i casi di lettura. */
async function seed(filePath, contentType = "image/jpeg") {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.storage().ref(filePath).put(bytes(16), {contentType});
  });
}

before(async () => {
  const hostPort = process.env.FIREBASE_STORAGE_EMULATOR_HOST;
  if (!hostPort) throw new Error("Storage emulator required.");
  const [host, port] = hostPort.split(":");
  testEnv = await initializeTestEnvironment({
    projectId,
    storage: {
      host,
      port: Number(port),
      rules: fs.readFileSync(
        path.resolve(__dirname, "../storage.rules"),
        "utf8",
      ),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearStorage();
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

test("utente non autenticato non legge foto profilo né copertine", async () => {
  await seed(profilePath(OWNER));
  await seed(coverPath(OWNER));
  const storage = storageAs(null);
  await assertFails(storage.ref(profilePath(OWNER)).getMetadata());
  await assertFails(storage.ref(coverPath(OWNER)).getMetadata());
});

test("utente non autenticato non carica", async () => {
  const storage = storageAs(null);
  await assertFails(
    storage.ref(profilePath(OWNER)).put(bytes(16), {contentType: "image/jpeg"}),
  );
});

test("utente autenticato legge foto profilo e copertine (anche altrui)",
  async () => {
    await seed(profilePath(OWNER));
    await seed(coverPath(OWNER));
    const storage = storageAs(OTHER);
    await assertSucceeds(storage.ref(profilePath(OWNER)).getMetadata());
    await assertSucceeds(storage.ref(coverPath(OWNER)).getMetadata());
  });

test("il proprietario carica foto profilo e copertina", async () => {
  const storage = storageAs(OWNER);
  await assertSucceeds(
    storage.ref(profilePath(OWNER)).put(bytes(1024), {contentType: "image/jpeg"}),
  );
  await assertSucceeds(
    storage.ref(coverPath(OWNER, "cover_1.png"))
      .put(bytes(1024), {contentType: "image/png"}),
  );
});

test("il proprietario sostituisce un file esistente (update)", async () => {
  await seed(profilePath(OWNER));
  const storage = storageAs(OWNER);
  await assertSucceeds(
    storage.ref(profilePath(OWNER)).put(bytes(64), {contentType: "image/webp"}),
  );
});

test("un altro utente non scrive nei percorsi altrui", async () => {
  const storage = storageAs(OTHER);
  await assertFails(
    storage.ref(profilePath(OWNER)).put(bytes(16), {contentType: "image/jpeg"}),
  );
  await assertFails(
    storage.ref(coverPath(OWNER)).put(bytes(16), {contentType: "image/jpeg"}),
  );
});

test("un altro utente non cancella nei percorsi altrui", async () => {
  await seed(profilePath(OWNER));
  await seed(coverPath(OWNER));
  const storage = storageAs(OTHER);
  await assertFails(storage.ref(profilePath(OWNER)).delete());
  await assertFails(storage.ref(coverPath(OWNER)).delete());
});

test("file oltre i 5 MB rifiutato (anche esattamente 5 MB)", async () => {
  const storage = storageAs(OWNER);
  await assertFails(
    storage.ref(profilePath(OWNER))
      .put(bytes(5 * MB + 1), {contentType: "image/jpeg"}),
  );
  await assertFails(
    storage.ref(coverPath(OWNER))
      .put(bytes(5 * MB), {contentType: "image/jpeg"}),
  );
});

test("file appena sotto i 5 MB accettato", async () => {
  const storage = storageAs(OWNER);
  await assertSucceeds(
    storage.ref(coverPath(OWNER))
      .put(bytes(5 * MB - 1), {contentType: "image/jpeg"}),
  );
});

test("file non immagine rifiutato", async () => {
  const storage = storageAs(OWNER);
  await assertFails(
    storage.ref(profilePath(OWNER, "doc.pdf"))
      .put(bytes(16), {contentType: "application/pdf"}),
  );
  await assertFails(
    storage.ref(coverPath(OWNER, "note.txt"))
      .put(bytes(16), {contentType: "text/plain"}),
  );
});

test("il proprietario cancella foto profilo e copertina", async () => {
  await seed(profilePath(OWNER));
  await seed(coverPath(OWNER));
  const storage = storageAs(OWNER);
  await assertSucceeds(storage.ref(profilePath(OWNER)).delete());
  await assertSucceeds(storage.ref(coverPath(OWNER)).delete());
});

test("percorsi fuori da quelli previsti sempre negati", async () => {
  await seed(`users/${OWNER}/documents/file.jpg`);
  await seed("public/banner.jpg");
  const storage = storageAs(OWNER);
  const jpeg = {contentType: "image/jpeg"};
  await assertFails(storage.ref(`users/${OWNER}/documents/file.jpg`).getMetadata());
  await assertFails(storage.ref(`users/${OWNER}/documents/new.jpg`).put(bytes(16), jpeg));
  await assertFails(storage.ref(`users/${OWNER}/documents/file.jpg`).delete());
  await assertFails(storage.ref("public/banner.jpg").getMetadata());
  await assertFails(storage.ref("public/new.jpg").put(bytes(16), jpeg));
  // sottocartelle dentro profile/ e cover/ non sono coperte dalle regole
  await assertFails(storage.ref(`users/${OWNER}/profile/a/b.jpg`).put(bytes(16), jpeg));
  await assertFails(
    storage.ref(`users/${OWNER}/trips/trip-1/cover/a/b.jpg`).put(bytes(16), jpeg),
  );
});
