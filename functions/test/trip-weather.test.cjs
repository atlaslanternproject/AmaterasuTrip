"use strict";

// Meteo del viaggio (nuova tappa 1b): sintesi delle risposte Open-Meteo,
// periodi del clima tipico, giorno del viaggio e cache esclusa dalla
// duplicazione. Nessuna chiamata di rete. Serve la build.
// Uso: node --test functions/test/trip-weather.test.cjs

const test = require("node:test");
const assert = require("node:assert/strict");
const {Timestamp} = require("firebase-admin/firestore");
const om = require("../lib/weather/weather-open-meteo.js");
const climate = require("../lib/weather/weather-climate.js");
const {shouldCopyTripSubcollection} =
  require("../lib/trip-management/trip-duplication-policy.js");

test("forecast keeps days and hours in the small shape", () => {
  const shaped = om.shapeForecast({
    timezone: "Europe/Rome",
    daily: {
      time: ["2026-11-25"], weather_code: [61], temperature_2m_max: [14.26],
      temperature_2m_min: [7.04], precipitation_probability_max: [80],
      precipitation_sum: [5.5], sunrise: ["2026-11-25T07:12"],
      sunset: ["2026-11-25T16:44"], uv_index_max: [1.2],
      wind_speed_10m_max: [22],
    },
    hourly: {
      time: ["2026-11-25T00:00"], temperature_2m: [8], weather_code: [3],
      precipitation_probability: [null], wind_speed_10m: [5],
    },
  });
  assert.equal(shaped.timezone, "Europe/Rome");
  assert.deepEqual(shaped.days[0], {
    date: "2026-11-25", code: 61, max: 14.3, min: 7, rain: 80, precip: 5.5,
    sunrise: "2026-11-25T07:12", sunset: "2026-11-25T16:44", uv: 1.2,
    wind: 22,
  });
  assert.deepEqual(shaped.hours[0],
    {time: "2026-11-25T00:00", temp: 8, rain: null, code: 3, wind: 5});
  assert.deepEqual(om.shapeForecast({}), {timezone: null, days: [], hours: []});
});

test("air quality and pollen: highest value per day, missing pollen left out",
  () => {
    const days = om.shapeAir({hourly: {
      time: ["2026-04-01T10:00", "2026-04-01T11:00", "2026-04-02T10:00"],
      european_aqi: [30, 45, 20],
      birch_pollen: [10, 55, null],
      grass_pollen: [null, null, null],
    }});
    assert.deepEqual(days, [
      {date: "2026-04-01", aqi: 45, pollen: {birch: 55}},
      {date: "2026-04-02", aqi: 20, pollen: {}},
    ]);
  });

test("urls ask only the needed values and never a key", () => {
  const url = om.forecastUrl(41.90278, 12.49636);
  assert.match(url, /latitude=41\.903&longitude=12\.496&timezone=auto/);
  assert.match(url, /forecast_days=16/);
  assert.doesNotMatch(url + om.airUrl(1, 2), /key|apikey/i);
  assert.match(om.climateUrl(1, 2, "2025-08-01", "2025-08-14"),
    /start_date=2025-08-01&end_date=2025-08-14/);
});

test("climate periods: same days of the 3 previous years, max 14 days", () => {
  assert.deepEqual(
    climate.climatePeriods("2027-08-01", "2027-08-30", "2026-11-25"), [
      {from: "2026-08-01", to: "2026-08-14"},
      {from: "2025-08-01", to: "2025-08-14"},
      {from: "2024-08-01", to: "2024-08-14"},
    ]);
  // A trip starting in a few days: last year is already in the history.
  assert.deepEqual(
    climate.climatePeriods("2026-11-28", "2026-11-30", "2026-11-25")[0],
    {from: "2025-11-28", to: "2025-11-30"});
  // Periods not yet in the history (less than a week ago) are skipped.
  assert.deepEqual(
    climate.climatePeriods("2027-11-20", "2027-11-22", "2026-11-25")[0],
    {from: "2025-11-20", to: "2025-11-22"});
});

test("climate summary: averages and share of rainy days", () => {
  const summary = climate.summarizeClimate([
    {daily: {temperature_2m_max: [30, 32], temperature_2m_min: [20, 22],
      precipitation_sum: [0, 4]}},
    {daily: {temperature_2m_max: [28], temperature_2m_min: [18],
      precipitation_sum: [0.2]}},
  ], [2026, 2025]);
  assert.deepEqual(summary,
    {years: [2026, 2025], max: 30, min: 20, precip: 1.4, rainyDays: 33});
  assert.equal(climate.summarizeClimate([{}], [2026]), null);
});

test("trip day: midnight saved in any time zone is the same day", () => {
  const {tripDay} = climate;
  // 1 Aug 2027 at midnight in Rome (UTC+2) and in New York (UTC-4).
  assert.equal(tripDay(Timestamp.fromDate(
    new Date("2027-07-31T22:00:00Z"))), "2027-08-01");
  assert.equal(tripDay(Timestamp.fromDate(
    new Date("2027-08-01T04:00:00Z"))), "2027-08-01");
  assert.equal(tripDay("2027-08-01"), null);
});

test("the weather cache is never copied by trip duplication", () => {
  assert.equal(shouldCopyTripSubcollection("weatherCache"), false);
});
