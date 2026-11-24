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
| Info paese | script in tool/ che rigenera un file dai dati aperti (es. REST Countries / Wikidata) con fonte, licenza e data | no | nessuna chiamata dall'app |
| Stato volo | solo link a un sito pubblico (FlightAware / Flightradar24) dal numero volo | no | nessuna API |
| 3B Meteo | solo link alla pagina della città | no | nessuna API |

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

### Frankfurter (cambi)
- Gratuita, senza chiave, open source (dati BCE). Il sito ufficiale non
  indica limiti; directory terze parlano di limiti "di buon uso" non
  pubblicati e il sito consiglia di tenere i dati in cache.
- Già in cache nell'app e salvata nelle spese dal server: va bene così.
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
