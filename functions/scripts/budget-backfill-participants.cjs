"use strict";

// One-time backfill for legacy shared expenses. Dry-run unless --apply.
// Run with local ADC credentials; review project and dry-run output first.
const admin = require("../node_modules/firebase-admin");
const args = process.argv.slice(2);
const match = args.find((value) => value.startsWith("--project="));
const projectId = match ? match.slice("--project=".length) : "";
const apply = args.includes("--apply");
if (!/^[a-z][a-z0-9-]{4,29}$/.test(projectId)) {
  console.error("Required: --project=PROJECT_ID [--apply]");
  process.exit(2);
}
if (apply && !args.includes("--confirm-production-write")) {
  console.error("Write requires --apply --confirm-production-write");
  process.exit(2);
}
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId,
});
const db = admin.firestore();
async function main() {
  let visited = 0;
  let missing = 0;
  let fixed = 0;
  let mismatched = 0;
  const trips = await db.collection("trips").get();
  for (const trip of trips.docs) {
    const expenses = await trip.ref.collection("budgetSharedExpenses").get();
    for (const doc of expenses.docs) {
      visited++;
      const data = doc.data();
      const shares = data.snapshot?.shares ?? {};
      const advances = data.snapshot?.advances ?? {};
      const ids = [...new Set([...Object.keys(shares), ...Object.keys(advances)])].sort();
      if (!ids.length) {
        throw new Error("Expense has no participants (trip id redacted)");
      }
      const existing = data.participantUids;
      if (Array.isArray(existing)) {
        if (JSON.stringify([...new Set(existing)].sort()) !== JSON.stringify(ids)) {
          mismatched++;
          if (apply) {
            throw new Error("Existing participantUids mismatches snapshot; review required");
          }
        }
        continue;
      }
      missing++;
      if (apply) {
        // Transaction prevents silently updating documents that changed during migration.
        await db.runTransaction(async (tx) => {
          const current = await tx.get(doc.ref);
          const fresh = current.data();
          if (!fresh) throw new Error("Missing expense during migration");
          const latest = [...new Set([
            ...Object.keys(fresh.snapshot?.shares ?? {}),
            ...Object.keys(fresh.snapshot?.advances ?? {}),
          ])].sort();
          if (!latest.length) throw new Error("No current expense participants");
          if (fresh.participantUids !== undefined) {
            if (JSON.stringify(fresh.participantUids) !== JSON.stringify(latest)) {
              throw new Error("Concurrent participant change; aborted");
            }
            return;
          }
          tx.update(doc.ref, {participantUids: latest});
        });
        fixed++;
      }
    }
  }
  console.log(JSON.stringify({projectId, mode: apply ? "APPLY" : "DRY_RUN", visited, missing, fixed, mismatched}));
  if (mismatched > 0) process.exitCode = 3;
}
main().catch((error) => { console.error(error.message); process.exitCode = 1; });
