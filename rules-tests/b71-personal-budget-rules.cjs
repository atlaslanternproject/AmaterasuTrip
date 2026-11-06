"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails
} = require("@firebase/rules-unit-testing");
const {
  doc,
  collection,
  getDoc,
  getDocs,
  setDoc,
  deleteDoc,
  serverTimestamp
} = require("firebase/firestore");

async function main() {
  const projectId = "demo-amaterasu-b71";

  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error("Firestore emulator required.");
  }

  const rules = fs.readFileSync(
    path.resolve(__dirname, "../firestore.rules"),
    "utf8"
  );

  const env = await initializeTestEnvironment({
    projectId,
    firestore: {rules}
  });

  try {
    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "trips", "tripB71"), {
        ownerUid: "atlas",
        memberUids: ["atlas", "yato"],
        status: "active",
        currency: "EUR"
      });
    });

    const atlas = env.authenticatedContext(
      "atlas", {email_verified: true}
    ).firestore();

    const yato = env.authenticatedContext(
      "yato", {email_verified: true}
    ).firestore();

    const stranger = env.authenticatedContext(
      "stranger", {email_verified: true}
    ).firestore();

    const base = [
      "trips", "tripB71", "budgetPrivateOwners"
    ];

    const atlasBudget = doc(
      atlas, ...base, "atlas", "settings", "personalBudget"
    );

    const yatoBudgetFromAtlas = doc(
      atlas, ...base, "yato", "settings", "personalBudget"
    );

    const atlasBudgetFromYato = doc(
      yato, ...base, "atlas", "settings", "personalBudget"
    );

    const atlasBudgetFromStranger = doc(
      stranger, ...base, "atlas", "settings", "personalBudget"
    );

    const yatoBudget = doc(
      yato, ...base, "yato", "settings", "personalBudget"
    );

    const valid = (amountMinor = 300000, currency = "EUR") => ({
      amountMinor,
      currency,
      updatedAt: serverTimestamp()
    });

    await assertSucceeds(setDoc(atlasBudget, valid()));
    console.log("PASS: Atlas creates own budget");

    await assertSucceeds(getDoc(atlasBudget));
    console.log("PASS: Atlas reads own budget");

    await assertSucceeds(setDoc(atlasBudget, valid(350000)));
    console.log("PASS: Atlas updates own budget");

    await assertSucceeds(setDoc(yatoBudget, valid(500000, "JPY")));
    console.log("PASS: Yato creates own budget");

    await assertFails(getDoc(atlasBudgetFromYato));
    await assertFails(getDoc(yatoBudgetFromAtlas));
    await assertFails(getDoc(atlasBudgetFromStranger));
    console.log("PASS: other users cannot read private budgets");

    await assertFails(setDoc(atlasBudgetFromYato, valid(1)));
    await assertFails(deleteDoc(yatoBudgetFromAtlas));
    console.log("PASS: other users cannot change private budgets");

    await assertFails(setDoc(atlasBudget, valid(-100)));
    await assertFails(setDoc(atlasBudget, valid(0)));
    await assertFails(setDoc(atlasBudget, valid(100, "INVALID")));
    await assertFails(setDoc(atlasBudget, {
      ...valid(),
      extraField: true
    }));
    console.log("PASS: invalid budget data rejected");

    // Existing owner-wide private read rules permit listing
    // the owner's own settings. Other members remain denied.
    await assertSucceeds(getDocs(collection(
      atlas, ...base, "atlas", "settings"
    )));
    await assertFails(getDocs(collection(
      yato, ...base, "atlas", "settings"
    )));
    console.log("PASS: own settings accessible; others denied");

    await assertFails(setDoc(doc(
      atlas, ...base, "atlas", "expenses", "forged"
    ), {
      title: "Unauthorized expense"
    }));
    console.log("PASS: financial write protection preserved");

    await assertSucceeds(deleteDoc(atlasBudget));
    console.log("PASS: Atlas removes own budget");

    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(
        context.firestore(), "trips", "tripB71"
      ), {
        ownerUid: "atlas",
        memberUids: ["atlas"],
        status: "active",
        currency: "EUR"
      });
    });

    await assertFails(getDoc(yatoBudget));
    await assertFails(setDoc(yatoBudget, valid(900000)));
    console.log("PASS: revoked member has no access");

    console.log("=== B7.1 FIRESTORE PRIVACY PASS ===");
  } finally {
    await env.cleanup();
  }
}

main().catch((error) => {
  console.error("B7.1 FIRESTORE PRIVACY FAIL:", error);
  process.exitCode = 1;
});