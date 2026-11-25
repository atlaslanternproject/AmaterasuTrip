"use strict";

// Piano della migrazione dei fusi orari dei trasporti (Extra C): per ogni
// offset salvato ("+01:00") propone il nome del fuso IANA equivalente da
// mettere in extras.departureZone / extras.arrivalZone. Gli offset, le
// date e gli orari NON cambiano: il risultato visibile resta identico.
// Un fuso si propone solo se, in quella data, dà esattamente lo stesso
// offset (controllo con Intl); altrimenti il campo si salta e si segnala.

/** Fixed zones (no daylight saving) for offsets that are not whole hours. */
const FIXED = {
  "+05:30": "Asia/Kolkata",
  "+05:45": "Asia/Kathmandu",
  "+09:30": "Australia/Darwin",
  "+03:30": "Asia/Tehran",
  "+04:30": "Asia/Kabul",
  "+06:30": "Asia/Yangon",
  "+08:45": "Australia/Eucla",
  "-09:30": "Pacific/Marquesas",
};

/**
 * IANA zone with the same fixed offset, or null.
 * @param {string} offset Like "+01:00".
 * @return {string|null} Zone name.
 */
function zoneForOffset(offset) {
  const m = /^([+-])(\d{2}):(\d{2})$/.exec(offset || "");
  if (!m) return null;
  if (m[3] !== "00") return FIXED[offset] || null;
  const hours = Number(m[2]);
  if (hours === 0) return "Etc/UTC";
  // Etc/GMT names have the opposite sign: UTC+1 is Etc/GMT-1.
  return `Etc/GMT${m[1] === "+" ? "-" : "+"}${hours}`;
}

/**
 * Offset of [zone] on [day] (noon UTC) as "+HH:MM".
 * @param {string} zone IANA zone.
 * @param {string} day "YYYY-MM-DD".
 * @return {string} Offset.
 */
function offsetOn(zone, day) {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: zone, timeZoneName: "longOffset",
  }).formatToParts(new Date(`${day}T12:00:00Z`));
  const name = parts.find((p) => p.type === "timeZoneName").value;
  if (name === "GMT") return "+00:00";
  return name.replace("GMT", "");
}

/**
 * What the migration would write for one transport document.
 * @param {object} data Firestore data.
 * @return {{set: object, skipped: string[]}} Fields to add and skipped ones.
 */
function planTransport(data) {
  const extras = data.extras && typeof data.extras === "object" ?
    data.extras : {};
  const set = {};
  const skipped = [];
  for (const [field, offsetKey, dayKey] of [
    ["departureZone", "departureOffset", "departureDate"],
    ["arrivalZone", "arrivalOffset", "arrivalDate"],
  ]) {
    const offset = data[offsetKey];
    if (typeof offset !== "string" || extras[field]) continue;
    const day = data[dayKey] || data.departureDate;
    const zone = zoneForOffset(offset);
    if (!zone || offsetOn(zone, day) !== offset) {
      skipped.push(`${offsetKey} ${offset}`);
      continue;
    }
    set[field] = zone;
  }
  return {set, skipped};
}

module.exports = {zoneForOffset, offsetOn, planTransport};
