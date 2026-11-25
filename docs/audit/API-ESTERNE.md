# API esterne: termini, limiti e scelta (Passo 1c, prompt v2)

Ultima verifica: 24/11/2026, su fonti pubbliche (link sotto). I limiti
possono cambiare: ricontrollare prima di ogni nuova funzione.
"Da verificare" = non confermato da una fonte ufficiale.

## Riepilogo e scelta
| Bisogno | Scelta proposta | Chiave | Da dove chiamarla |
|---|---|---|---|
| Meteo (previsioni, alba/tramonto, pioggia, qualità aria) | Open-Meteo | no | Cloud Function con cache condivisa per viaggio (limite per IP e una sola chiamata per tutti i membri) |
| Clima tipico del periodo | Open-Meteo Historical / Climate API | no | Cloud Function, cache lunga (settimane) |
| Geocoding città → fuso orario IANA | Open-Meteo Geocoding API (restituisce già il fuso) | no | app, solo quando si cerca una città |
| Cambi valuta | Frankfurter (già in uso) | no | come oggi (app con cache + server per le spese) |
| Info paese | Wikidata (CC0 1.0) con lo script tool/build_country_info.mjs che rigenera assets/country_info/country_info.json; link ufficiali Viaggiare Sicuri e consolati Farnesina | no | nessuna chiamata dall'app (in uso dalla 1.51.0) |
| Stato volo | solo link a un sito pubblico (FlightAware / Flightradar24) dal numero volo | no | nessuna API |
| 3B Meteo | solo link alla pagina della città | no | nessuna API |
| Orari e prezzo dei ristoranti | Google Places (stessa richiesta dei contatti) | sì (già in uso) | app, solo su "Orari e prezzi" o scegliendo il luogo |

## Dettaglio
### Open-Meteo
- Gratuita solo per uso NON commerciale, meno di 10.000 chiamate al
  giorno, 5.000 all'ora, 600 al minuto; nessuna garanzia di servizio.
- Dati con licenza CC BY 4.0: obbligo di citare la fonte ("Dati meteo:
  Open-Meteo.com") e di indicare modifiche.
- Uso commerciale o oltre i limiti: abbonamento a pagamento.
- Amaterasu Trip è gratuita e senza pubblicità: rientra nell'uso non
  commerciale finché resta tale (da rivedere se cambia il modello).
- Fonti: [termini](https://open-meteo.com/en/terms),
  [licenza](https://open-meteo.com/en/licence),
  [prezzi](https://open-meteo.com/en/pricing).

### Google Weather API (Maps Platform)
- È uno SKU "Essentials": di norma 10.000 richieste gratuite al mese
  per SKU, poi a pagamento (soglia esatta da verificare nella pagina
  prezzi). Richiede la chiave e la fatturazione attiva.
- Termini Maps Platform: i dati non vanno salvati oltre quanto
  consentito (cache limitata).
- Proposta: non usarla (Open-Meteo basta); eventualmente solo dopo ok.
- Fonti: [usage and billing](https://developers.google.com/maps/documentation/weather/usage-and-billing),
  [categorie di prezzo](https://developers.google.com/maps/billing-and-pricing/pricing-categories).

### Aeronautica Militare (meteoam.it)
- Nessuna API pubblica documentata trovata. Le condizioni d'uso dicono
  che il Servizio Meteorologico detiene i diritti sui dati e che i
  servizi a valore aggiunto per terzi richiedono una licenza specifica;
  i dati si chiedono su richiesta (info.meteo@am.difesa.it).
- Dal 1/10/2025 i dati ECMWF sono aperti (CC BY 4.0), ma sono dati
  ECMWF, non di meteoam.
- Proposta: solo link alla pagina della città su meteoam.it.
- Fonti: [condizioni di utilizzo](https://www.meteoam.it/it/condizioni-utilizzo),
  [data policy ECMWF](https://www.meteoam.it/it/in-primo-piano/meteorologia---da-ottobre-entra-in-vigore-la-nuova-data-policy-dell-ecmwf-).

### 3B Meteo
- Nessuna API pubblica gratuita: solo pulsante "Apri su 3B Meteo" con
  il link alla pagina della città, nessun dato scaricato.

### Google Places: orari e prezzo dei ristoranti (v1.29.0)
- Nessuna nuova chiamata: orari (regularOpeningHours) e prezzo
  (priceLevel, priceRange) sono chiesti nella stessa richiesta dei
  contatti (telefono, sito), che è già uno SKU "Place Details
  Enterprise". Stesso costo per richiesta.
- La richiesta parte solo scegliendo il luogo nell'editor o toccando
  "Orari e prezzi" nella card (mai per ogni card); resta in memoria per
  la sessione e non si salva su Firestore.
- Limite: quota gratuita mensile dello SKU Enterprise (vedi COSTI.md);
  se finisce, il pannello mostra "riprova più tardi" (funzione limitata,
  non bloccata).
- Fonti: [Place Details (New) fields](https://developers.google.com/maps/documentation/places/web-service/place-details),
  [usage and billing](https://developers.google.com/maps/documentation/places/web-service/usage-and-billing).

### Open-Meteo: Meteo del viaggio (in uso dalla 1.50.0)
- Chiamate solo dalla funzione getTripWeather (server, europe-west1),
  mai dall'app né per ogni card: previsione (16 giorni, giornaliera e
  oraria), qualità dell'aria e pollini (5 giorni; pollini solo in Europa
  e in stagione), storico degli stessi giorni dei 3 anni precedenti
  (al massimo 14 giorni per anno) per il clima tipico.
- Cache condivisa per viaggio in trips/{tripId}/weatherCache/current
  (scritta solo dal server, negata ai client dalle regole): previsione e
  aria per 3 ore, clima per 30 giorni; si rifà se cambiano destinazione o
  date. L'app chiama la funzione una volta per viaggio e per sessione.
- Conto delle chiamate: al massimo 3 ogni 3 ore per viaggio (la
  previsione ha più di 10 variabili e Open-Meteo la conta come 2) più 3
  al mese per il clima: molto sotto i 10.000 al giorno.
- Se il servizio non risponde: dati dell'ultimo aggiornamento con un
  avviso; senza dati salvati "Meteo non disponibile ora" con "Riprova";
  aria e clima mancanti non bloccano la pagina (funzione limitata, non
  bloccata).
- Fonte citata nella pagina: "Dati meteo: Open-Meteo.com (CC BY 4.0),
  riassunti per giorno" (indicazione delle modifiche).
- Fonti: [forecast API](https://open-meteo.com/en/docs),
  [air quality API](https://open-meteo.com/en/docs/air-quality-api),
  [historical API](https://open-meteo.com/en/docs/historical-weather-api).

### 3B Meteo (link, in uso dalla 1.50.0)
- Solo il pulsante "Apri su 3B Meteo", nessun dato scaricato. Città
  italiane: pagina /meteo/<città> (spazi con "+", senza accenti, provato
  su roma, reggio+emilia, forli). Estero: il sito vuole un suo numero per
  città che l'app non conosce, quindi si apre la home con la ricerca.

### Wikidata: Info paese (in uso dalla 1.51.0)
- Dati CC0 1.0 (nessun obbligo, la fonte si cita comunque su ogni voce).
  Interrogazione SPARQL pubblica, senza chiave, con limiti di buon uso
  (tempo massimo per richiesta e User-Agent descrittivo).
- Chiamata solo dallo script tool/build_country_info.mjs, a mano, da chi
  sviluppa (7 richieste in tutto): l'app legge solo il file generato.
- Voci: prefisso, numeri di emergenza, prese (lettera del tipo quando
  Wikidata la indica, altrimenti il nome dello standard), tensione, lato
  di guida, fusi. Frequenza, acqua potabile e requisiti d'ingresso non
  hanno una fonte aperta affidabile: non si mostrano, restano i link
  ufficiali. Lo script si ferma senza scrivere se i dati sembrano errati.
- REST Countries (proposta iniziale): la versione libera v3.1 risponde
  "deprecated" e rimanda alla v5; non usata.
- Viaggiare Sicuri: la pagina del paese è /find-country/country/<codice
  ISO a 3 lettere> (verificato nel codice del sito, campo "Codice-3").
  Consolati: https://serviziconsolari.esteri.it/home/cerca-consolato
  (collegato dalla home della Farnesina).
- Fonti: [Wikidata licenza](https://www.wikidata.org/wiki/Wikidata:Licensing),
  [query service](https://www.wikidata.org/wiki/Wikidata:SPARQL_query_service).

### Open-Meteo Geocoding (fuso orario per città, in uso dalla 1.38.0)
- Gratuita, senza chiave, uso non commerciale (stessi termini di
  Open-Meteo sopra); restituisce città, regione, paese e fuso IANA.
- Chiamata dall'app solo quando si preme "Cerca" nel selettore del fuso
  (8 risultati), con le risposte in memoria per la sessione: nessuna
  chiamata per card né in ciclo.
- Lo scarto da UTC e l'ora locale si calcolano nel browser (Intl), senza
  altre API.
- Se il servizio non risponde: "Ricerca non disponibile ora" e restano
  l'ora e l'offset già salvati (funzione limitata, non bloccata).
- Fonte: [geocoding API](https://open-meteo.com/en/docs/geocoding-api).

### Frankfurter (cambi)
- Gratuita, senza chiave, open source (dati BCE). Il sito ufficiale non
  indica limiti; directory terze parlano di limiti "di buon uso" non
  pubblicati e il sito consiglia di tenere i dati in cache.
- Già in cache nell'app e salvata nelle spese dal server: va bene così.
- Ristoranti (v1.29.0): conversione del prezzo di Google nella valuta
  del viaggio, chiesta solo aprendo "Orari e prezzi" (cache 30 minuti).
- Fonti: [frankfurter.dev](https://frankfurter.dev/),
  [GitHub](https://github.com/lineofflight/frankfurter).

### Info paese (REST Countries o simili)
- REST Countries: servizio gratuito senza chiave, ma senza garanzie e
  con periodi di indisponibilità (da verificare). Per questo la
  proposta è uno script in tool/ che rigenera un file statico con fonte,
  licenza e data per ogni voce; le voci senza fonte affidabile non si
  mostrano e resta il link ufficiale (es. Viaggiare Sicuri della
  Farnesina).

### Stato volo
- AviationStack: piano gratuito di circa 100 richieste al mese, solo
  HTTP (non HTTPS) e uso non commerciale secondo fonti terze: non
  adatto a un sito HTTPS.
- OpenSky Network: dati ADS-B gratuiti per ricerca/uso non commerciale
  con crediti giornalieri (da verificare sulla documentazione ufficiale).
- AeroDataBox: limiti del piano gratuito da verificare.
- Proposta: solo link a un sito di tracking pubblico dal numero volo;
  nessuna API senza il tuo ok.
- Fonti: [AviationStack prezzi](https://aviationstack.com/pricing),
  [changelog](https://docs.apilayer.com/changelog/docs/aviationstack).

## Attribuzione delle foto di Google Places
- I termini chiedono di mostrare l'attribuzione dell'autore di ogni
  foto che la fornisce (nome con link al profilo), vicino all'immagine.
- Se i dati Places si mostrano su una pagina senza mappa Google, va
  mostrata l'attribuzione "Google Maps"; i dati Places non vanno mostrati
  su mappe di altri fornitori.
- Minimo da mostrare (tappa 1b): nel carosello aperto, in piccolo in un
  angolo dell'immagine, "Foto: {autore}" con link e "Google Maps"; nella
  card, solo la piccola scritta "Google Maps".
- Fonti: [policy Places API](https://developers.google.com/maps/documentation/places/web-service/policies),
  [Place Photos (New)](https://developers.google.com/maps/documentation/places/web-service/place-photos),
  [policy Maps JavaScript API](https://developers.google.com/maps/documentation/javascript/policies).
