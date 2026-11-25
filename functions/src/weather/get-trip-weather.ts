// Funzione "getTripWeather" (nuova tappa 1b): meteo della destinazione del
// viaggio per i soli membri. Cache condivisa in trips/{tripId}/weatherCache
// (scritta solo dal server, le regole la negano ai client): previsioni e
// aria per 3 ore, clima tipico per 30 giorni, una chiamata per tutti.

import {getFirestore} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";

import {requireVerifiedUid} from "../shared/require-verified-uid";
import {isTripMember} from "../shared/trip-access";
import {climatePeriods, summarizeClimate, tripDay} from "./weather-climate";
import {
  airUrl, climateUrl, fetchOpenMeteo, forecastUrl, shapeAir, shapeForecast,
} from "./weather-open-meteo";

const db = getFirestore();
const hourMs = 60 * 60 * 1000;
const forecastTtlMs = 3 * hourMs;
const climateTtlMs = 30 * 24 * hourMs;
const idPattern = /^[A-Za-z0-9_-]{1,128}$/;

const fresh = (part: {fetchedAt?: unknown} | undefined, ttl: number,
  now: number) => typeof part?.fetchedAt === "number" &&
  now - part.fetchedAt < ttl;

export const getTripWeather = onCall(
  {region: "europe-west1", timeoutSeconds: 30},
  async (request) => {
    const uid = requireVerifiedUid(request);
    const tripId = request.data?.tripId;
    if (typeof tripId !== "string" || !idPattern.test(tripId)) {
      throw new HttpsError("invalid-argument", "Invalid trip.");
    }
    const tripRef = db.collection("trips").doc(tripId);
    const trip = (await tripRef.get()).data();
    if (!trip || !isTripMember(trip, uid)) {
      throw new HttpsError("permission-denied", "Membership required.");
    }
    const place = trip.destinationData ?? {};
    const lat = place.latitude;
    const lng = place.longitude;
    if (typeof lat !== "number" || typeof lng !== "number") {
      throw new HttpsError("failed-precondition", "no-destination");
    }
    const start = tripDay(trip.startDate);
    const end = tripDay(trip.endDate) ?? start;
    const key = `${lat.toFixed(3)},${lng.toFixed(3)}`;
    const now = Date.now();
    const today = new Date(now).toISOString().slice(0, 10);
    const cacheRef = tripRef.collection("weatherCache").doc("current");
    const cached = (await cacheRef.get()).data() ?? {};
    const samePlace = cached.key === key;
    const update: Record<string, unknown> = {key};

    let forecast = samePlace ? cached.forecast : undefined;
    let air = samePlace ? cached.air : undefined;
    let stale = false;
    if (!fresh(forecast, forecastTtlMs, now)) {
      try {
        forecast = {
          ...shapeForecast(await fetchOpenMeteo(forecastUrl(lat, lng))),
          fetchedAt: now,
        };
        update.forecast = forecast;
      } catch (error) {
        if (!forecast) throw error;
        stale = true;
      }
      // Air quality is optional: without it the page still works.
      try {
        air = {days: shapeAir(await fetchOpenMeteo(airUrl(lat, lng))),
          fetchedAt: now};
        update.air = air;
      } catch {
        air = air ?? null;
      }
    }

    const period = start && end ? `${start}|${end}` : null;
    let climate = samePlace && cached.climate?.period === period ?
      cached.climate : undefined;
    if (period && !fresh(climate, climateTtlMs, now)) {
      const periods = climatePeriods(start!, end!, today);
      try {
        const answers = await Promise.all(periods.map((p) =>
          fetchOpenMeteo(climateUrl(lat, lng, p.from, p.to))));
        const years = periods.map((p) => Number(p.from.slice(0, 4)));
        climate = {...summarizeClimate(answers, years), period,
          fetchedAt: now};
        update.climate = climate;
      } catch {
        climate = climate ?? null;
      }
    }
    if (Object.keys(update).length > 1 || !samePlace) {
      await cacheRef.set(update, {merge: samePlace});
    }
    return {
      place: {
        name: place.locality ?? place.displayName ?? trip.destination ?? null,
        countryCode: place.countryCode ?? null,
      },
      tripStart: start,
      tripEnd: end,
      forecast,
      air: air ?? null,
      climate: climate ?? null,
      stale,
    };
  },
);
