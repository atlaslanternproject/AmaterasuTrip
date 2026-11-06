"use strict";
const assert = require("node:assert/strict");
const {validatePaymentMethods} =
  require("../functions/lib/budget/budget-payment-methods.js");

const snapshot = {
  total: {currency: "EUR", minorUnits: 10000},
  status: "paid",
  shares: {
    atlas: {currency: "EUR", minorUnits: 5000},
    yato: {currency: "EUR", minorUnits: 5000},
  },
  advances: {atlas: {currency: "EUR", minorUnits: 10000}},
};

const pay = (method, amount, payerUid = "atlas") => ({
  payerUid, method, minorUnits: amount,
});

assert.equal(validatePaymentMethods(undefined, snapshot), null);

assert.equal(validatePaymentMethods([
  pay("cash", 4000),
  pay("card", 6000),
], snapshot).length, 2);

assert.throws(() => validatePaymentMethods([
  pay("card", 10000, "yato"),
], snapshot));

assert.throws(() => validatePaymentMethods([
  pay("card", 5000),
], snapshot));

assert.throws(() => validatePaymentMethods([
  pay("card", 11000),
], snapshot));

assert.throws(() => validatePaymentMethods([
  pay("unknown", 10000),
], snapshot));

assert.equal(validatePaymentMethods([{
  ...pay("other", 10000),
  otherLabel: "Voucher",
}], snapshot)[0].otherLabel, "Voucher");

assert.deepEqual(validatePaymentMethods([], {
  ...snapshot,
  status: "planned",
  advances: {},
}), []);

console.log("=== B7.5.2 SERVER TEST PASS ===");
