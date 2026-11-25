// Fuori dal browser (test e piattaforme non web) non c'è Intl: le funzioni
// restituiscono null e AmaterasuZoneClock usa solo i fusi fissi Etc/GMT.

String? zoneOffset(String zone, DateTime day) => null;

String? zoneTime(String zone, DateTime at) => null;
