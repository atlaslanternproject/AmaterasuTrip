// Meteo del viaggio (nuova tappa 1b): chiamate a Open-Meteo (previsioni,
// qualità dell'aria e pollini, clima degli anni passati) e sintesi in un
// formato piccolo da salvare nella cache condivisa del viaggio. Nessuna
// chiave: dati CC BY 4.0 (citare "Open-Meteo.com").

import {HttpsError} from "firebase-functions/v2/https";

const maxDelayMs = 8000;

type Json = Record<string, unknown>;
type Series = Record<string, unknown[]>;

/**
 * Downloads one Open-Meteo answer; any problem becomes "unavailable".
 * @param {string} url Open-Meteo address.
 * @return {Promise<Object>} The JSON answer.
 */
export async function fetchOpenMeteo(url: string): Promise<Json> {
  let response: Response;
  try {
    response = await fetch(url, {signal: AbortSignal.timeout(maxDelayMs)});
  } catch {
    throw new HttpsError("unavailable", "Weather provider unavailable.");
  }
  if (!response.ok) {
    throw new HttpsError("unavailable", "Weather provider error.");
  }
  const value: unknown = await response.json();
  if (value === null || typeof value !== "object") {
    throw new HttpsError("unavailable", "Weather provider answer invalid.");
  }
  return value as Json;
}

const at = (lat: number, lng: number) =>
  `latitude=${lat.toFixed(3)}&longitude=${lng.toFixed(3)}&timezone=auto`;

export const forecastUrl = (lat: number, lng: number) =>
  "https://api.open-meteo.com/v1/forecast?" + at(lat, lng) +
  "&daily=weather_code,temperature_2m_max,temperature_2m_min," +
  "precipitation_probability_max,precipitation_sum,sunrise,sunset," +
  "uv_index_max,wind_speed_10m_max" +
  "&hourly=temperature_2m,precipitation_probability,weather_code," +
  "wind_speed_10m&forecast_days=16";

export const pollenKinds =
  ["alder", "birch", "grass", "mugwort", "olive", "ragweed"];

export const airUrl = (lat: number, lng: number) =>
  "https://air-quality-api.open-meteo.com/v1/air-quality?" + at(lat, lng) +
  "&hourly=european_aqi," + pollenKinds.map((k) => `${k}_pollen`).join(",") +
  "&forecast_days=5";

export const climateUrl = (
  lat: number, lng: number, from: string, to: string,
) =>
  "https://archive-api.open-meteo.com/v1/archive?" + at(lat, lng) +
  `&start_date=${from}&end_date=${to}` +
  "&daily=temperature_2m_max,temperature_2m_min,precipitation_sum";

const num = (v: unknown): number | null =>
  typeof v === "number" && Number.isFinite(v) ? Math.round(v * 10) / 10 :
    null;
const text = (v: unknown): string | null => typeof v === "string" ? v : null;
const series = (json: Json, key: string): Series => {
  const value = json[key];
  return value !== null && typeof value === "object" ? value as Series : {};
};
const list = (s: Series, key: string): unknown[] =>
  Array.isArray(s[key]) ? s[key] : [];

/**
 * Daily and hourly forecast in the small cached shape.
 * @param {Object} json Open-Meteo forecast answer.
 * @return {Object} Time zone, days and hours.
 */
export function shapeForecast(json: Json) {
  const d = series(json, "daily");
  const h = series(json, "hourly");
  const days = list(d, "time").map((date, i) => ({
    date: text(date),
    code: num(list(d, "weather_code")[i]),
    max: num(list(d, "temperature_2m_max")[i]),
    min: num(list(d, "temperature_2m_min")[i]),
    rain: num(list(d, "precipitation_probability_max")[i]),
    precip: num(list(d, "precipitation_sum")[i]),
    sunrise: text(list(d, "sunrise")[i]),
    sunset: text(list(d, "sunset")[i]),
    uv: num(list(d, "uv_index_max")[i]),
    wind: num(list(d, "wind_speed_10m_max")[i]),
  }));
  const hours = list(h, "time").map((time, i) => ({
    time: text(time),
    temp: num(list(h, "temperature_2m")[i]),
    rain: num(list(h, "precipitation_probability")[i]),
    code: num(list(h, "weather_code")[i]),
    wind: num(list(h, "wind_speed_10m")[i]),
  }));
  return {timezone: text(json.timezone), days, hours};
}

/**
 * Highest value of each day ("2026-11-25T13:00" -> "2026-11-25").
 * @param {Array} times Hourly times.
 * @param {Array} values Hourly values.
 * @return {Map} Highest value by day.
 */
function dailyMax(times: unknown[], values: unknown[]) {
  const out = new Map<string, number>();
  times.forEach((t, i) => {
    const v = num(values[i]);
    if (typeof t !== "string" || v === null) return;
    const day = t.slice(0, 10);
    out.set(day, Math.max(out.get(day) ?? v, v));
  });
  return out;
}

/**
 * Air quality (European index) and pollen, highest value per day.
 * @param {Object} json Open-Meteo air quality answer.
 * @return {Array} One entry per day.
 */
export function shapeAir(json: Json) {
  const h = series(json, "hourly");
  const times = list(h, "time");
  const aqi = dailyMax(times, list(h, "european_aqi"));
  const pollen = pollenKinds.map(
    (k) => [k, dailyMax(times, list(h, `${k}_pollen`))] as const);
  const days = [...new Set(times.filter((t): t is string =>
    typeof t === "string").map((t) => t.slice(0, 10)))];
  return days.map((date) => {
    const p: Record<string, number> = {};
    for (const [k, values] of pollen) {
      const v = values.get(date);
      if (v !== undefined) p[k] = v;
    }
    return {date, aqi: aqi.get(date) ?? null, pollen: p};
  });
}
