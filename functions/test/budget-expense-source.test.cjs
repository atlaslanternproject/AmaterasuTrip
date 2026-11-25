"use strict";

// Campi facoltativi di una spesa (sezione di origine e link): validi,
// assenti e non validi. Nessun effetto sui calcoli. Serve la build.
// Uso: node --test functions/test/budget-expense-source.test.cjs

const test = require("node:test");
const assert = require("node:assert/strict");
const {validateExpenseExtras} =
  require("../lib/budget/budget-expense-source.js");

test("no source and no link: nothing is saved", () => {
  assert.deepEqual(validateExpenseExtras(undefined, undefined), {});
  assert.deepEqual(validateExpenseExtras(null, ""), {});
});

test("valid source and link are kept", () => {
  assert.deepEqual(
    validateExpenseExtras(
      {section: "transports", id: "abc_1-2"},
      " https://www.ita-airways.com/booking ",
    ),
    {
      source: {section: "transports", id: "abc_1-2"},
      link: "https://www.ita-airways.com/booking",
    },
  );
});

test("invalid source or link is refused", () => {
  for (const source of [
    "transports",
    {section: "budget", id: "a"},
    {section: "stays", id: "a/b"},
    {section: "stays", id: ""},
    {section: "stays"},
  ]) {
    assert.throws(() => validateExpenseExtras(source, undefined));
  }
  for (const link of [
    "www.a.it",
    "ftp://a.it",
    "https://",
    "https://a.it/" + "x".repeat(2048),
    5,
  ]) {
    assert.throws(() => validateExpenseExtras(undefined, link));
  }
});
