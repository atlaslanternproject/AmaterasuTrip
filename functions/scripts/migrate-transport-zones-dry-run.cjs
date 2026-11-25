"use strict";

// Migrazione dei fusi orari (Extra C), SOLO LETTURA: non scrive nulla.
// Conta quanti documenti verrebbero cambiati e mostra due esempi
// prima/dopo per tipo (trasporti, prenotazioni, ristoranti), con i soli
// campi di data, ora e fuso (nessun nome, nessun id).
// Uso: node functions/scripts/migrate-transport-zones-dry-run.cjs --project=ID
// Credenziali: gcloud auth application-default login (ADC locali).
const admin = require("../node_modules/firebase-admin");
const {planTransport} = require("./transport-zone-plan.cjs");

const arg = process.argv.find((v) => v.startsWith("--project="));
const projectId = arg ? arg.slice("--project=".length) : "";
if (!/^[a-z][a-z0-9-]{4,29}$/.test(projectId)) {
  console.error("Uso: --project=PROJECT_ID");
  process.exit(2);
}
admin.initializeApp({
  credential: admin.credential.applicationDefault(), projectId,
});
const db = admin.firestore();

const pick = (data, keys) => Object.fromEntries(
  keys.filter((k) => data[k] !== undefined).map((k) => [k, data[k]]),
);
const TIME_KEYS = ["departureDate", "departureTime", "departureOffset",
  "arrivalDate", "arrivalTime", "arrivalOffset"];
const ZONE_KEYS = ["departureZone", "arrivalZone"];

async function main() {
  const report = {
    transports: {visited: 0, changed: 0, skipped: 0, examples: [], notes: []},
    reservations: {visited: 0, changed: 0, examples: []},
    restaurants: {visited: 0, changed: 0, examples: []},
  };
  const trips = await db.collection("trips").get();
  for (const trip of trips.docs) {
    const transports = await trip.ref.collection("transports").get();
    for (const doc of transports.docs) {
      const data = doc.data();
      const t = report.transports;
      t.visited++;
      const {set, skipped} = planTransport(data);
      if (skipped.length) {
        t.skipped++;
        t.notes.push(...skipped);
      }
      if (!Object.keys(set).length) continue;
      t.changed++;
      if (t.examples.length < 2) {
        const zones = pick(data.extras || {}, ZONE_KEYS);
        t.examples.push({
          prima: {...pick(data, TIME_KEYS), extras: zones},
          dopo: {...pick(data, TIME_KEYS), extras: {...zones, ...set}},
        });
      }
    }
    // Bookings and restaurants have only a local time and no zone today:
    // nothing to migrate (the new zone field stays empty until chosen).
    for (const name of ["reservations", "restaurants"]) {
      const snap = await trip.ref.collection(name).get();
      for (const doc of snap.docs) {
        const r = report[name];
        r.visited++;
        if (r.examples.length < 2) {
          const keys = name === "reservations" ?
            ["date", "time"] : ["reservationDate", "reservationTime"];
          const shown = pick(doc.data(), keys);
          r.examples.push({prima: shown, dopo: shown});
        }
      }
    }
  }
  console.log(JSON.stringify(report, null, 2));
  console.log("Nessun documento è stato modificato (solo lettura).");
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
