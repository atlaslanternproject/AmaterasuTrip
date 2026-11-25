// Clima tipico del periodo del viaggio (nuova tappa 1b): stesse date dei
// 3 anni precedenti (al massimo 14 giorni, una chiamata per anno) e media
// di massime, minime, pioggia e giorni di pioggia. Solo calcoli.

import {Timestamp} from "firebase-admin/firestore";

/** Years of history averaged for the typical climate of the period. */
export const climateYears = 3;
/** Longest period (days) asked to the history API, to stay in 1 call. */
export const climateMaxDays = 14;

const dayMs = 24 * 60 * 60 * 1000;
const hourMs = 60 * 60 * 1000;
const iso = (d: Date) => d.toISOString().slice(0, 10);
const parse = (s: string) => new Date(`${s}T00:00:00Z`);
const minusYears = (d: Date, years: number) => {
  const copy = new Date(d.getTime());
  copy.setUTCFullYear(copy.getUTCFullYear() - years);
  return copy;
};

/**
 * Past periods with the same calendar days as the trip (capped to
 * [climateMaxDays]); only periods ended at least a week before [today],
 * because the history arrives a few days late.
 * @param {string} start First trip day (YYYY-MM-DD).
 * @param {string} end Last trip day (YYYY-MM-DD).
 * @param {string} today Today (YYYY-MM-DD).
 * @return {Array} Past periods, most recent first.
 */
export function climatePeriods(start: string, end: string, today: string) {
  const from = parse(start);
  let to = parse(end);
  if (to < from) to = from;
  const cap = new Date(from.getTime() + (climateMaxDays - 1) * dayMs);
  if (to > cap) to = cap;
  const limit = parse(today).getTime() - 7 * dayMs;
  const periods: {from: string; to: string}[] = [];
  for (let back = 1; periods.length < climateYears && back <= 6; back++) {
    const pastTo = minusYears(to, back);
    if (pastTo.getTime() > limit) continue;
    periods.push({from: iso(minusYears(from, back)), to: iso(pastTo)});
  }
  return periods;
}

type Json = Record<string, unknown>;

const values = (json: Json, key: string): number[] => {
  const daily = json.daily as Record<string, unknown> | undefined;
  const raw = daily?.[key];
  return Array.isArray(raw) ?
    raw.filter((v): v is number => typeof v === "number" &&
      Number.isFinite(v)) : [];
};
const average = (list: number[]) => list.length === 0 ? null :
  Math.round(list.reduce((a, b) => a + b, 0) / list.length * 10) / 10;

/**
 * Averages of the past periods; null when no day came back.
 * @param {Array} answers Open-Meteo history answers.
 * @param {Array<number>} years Years of the answers.
 * @return {Object|null} Averages and share of rainy days.
 */
export function summarizeClimate(answers: Json[], years: number[]) {
  const max = answers.flatMap((a) => values(a, "temperature_2m_max"));
  const min = answers.flatMap((a) => values(a, "temperature_2m_min"));
  const rain = answers.flatMap((a) => values(a, "precipitation_sum"));
  if (max.length === 0 && min.length === 0) return null;
  const rainy = rain.filter((v) => v >= 1).length;
  return {
    years,
    max: average(max),
    min: average(min),
    precip: average(rain),
    rainyDays: rain.length === 0 ? null :
      Math.round(rainy / rain.length * 100),
  };
}

/**
 * Trip day as YYYY-MM-DD: midnight saved in any time zone up to ±12 h.
 * @param {unknown} value Saved trip date.
 * @return {string|null} The day, or null when it is not a date.
 */
export function tripDay(value: unknown): string | null {
  if (!(value instanceof Timestamp)) return null;
  return new Date(value.toMillis() + 12 * hourMs).toISOString().slice(0, 10);
}
