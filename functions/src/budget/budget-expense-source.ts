import {HttpsError} from "firebase-functions/v2/https";

// Campi facoltativi di una spesa che non toccano i calcoli: la sezione del
// viaggio che l'ha generata (per "Vai al trasporto / all'hotel...") e un
// link web. Validati qui, salvati così come sono.

/** Sections that can create an expense. */
export const EXPENSE_SOURCE_SECTIONS = [
  "stays",
  "transports",
  "reservations",
  "restaurants",
  "shoppingItems",
];

export interface ExpenseExtras {
  source?: {section: string; id: string};
  link?: string;
}

/**
 * Validates the optional source and link of a new expense.
 *
 * @param {unknown} rawSource {section, id} or undefined.
 * @param {unknown} rawLink Web address or undefined.
 * @return {ExpenseExtras} Fields to save (empty when none).
 */
export function validateExpenseExtras(
  rawSource: unknown,
  rawLink: unknown,
): ExpenseExtras {
  const extras: ExpenseExtras = {};
  if (rawSource !== undefined && rawSource !== null) {
    const source = rawSource as {section?: unknown; id?: unknown};
    if (typeof rawSource !== "object" ||
        typeof source.section !== "string" ||
        !EXPENSE_SOURCE_SECTIONS.includes(source.section) ||
        typeof source.id !== "string" ||
        !/^[A-Za-z0-9_-]{1,128}$/.test(source.id)) {
      throw new HttpsError("invalid-argument", "Invalid expense source.");
    }
    extras.source = {section: source.section, id: source.id};
  }
  if (rawLink !== undefined && rawLink !== null && rawLink !== "") {
    if (typeof rawLink !== "string" ||
        rawLink.length > 2048 ||
        !/^https?:\/\/[^\s/]+\S*$/.test(rawLink.trim())) {
      throw new HttpsError("invalid-argument", "Invalid expense link.");
    }
    extras.link = rawLink.trim();
  }
  return extras;
}
