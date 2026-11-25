# Costi: chiamate esterne e letture (Passo 1b, prompt v2)

Obiettivo: sotto 5 euro al mese, idealmente 0. Analisi del codice alla
versione 1.23.0. "Normale" = un viaggio di 4 persone, una sessione di
circa 15 minuti; "peggiore" = un utente che apre tutte le sezioni con
molti elementi.

## 1. Google Maps Platform (chiave web, fatturazione Google Cloud)
| Uso | Dove | Quando | Richieste per sessione (normale / peggiore) |
|---|---|---|---|
| Maps JavaScript API (caricamento libreria) | web/google_maps_loader.js | alla prima ricerca di luogo o mappa | 1 / 1 |
| Mappa dinamica (Dynamic Maps) | creazione viaggio, mappa del mondo della destinazione | solo nella creazione | 0 / 1 |
| Autocomplete (Places New, sessioni) | web/amaterasu_maps_bridge.js (ricerca luogo) | a ogni ricerca scritta | 3 / 30 |
| Place Details (Essentials: id, nome, indirizzo, coordinate) | scelta di un risultato | a ogni luogo scelto | 1 / 10 |
| Place Details (Enterprise: telefono e sito) | web/amaterasu_place_info.js | luogo scelto negli editor; "Contatta" | 1 / 10 |
| Place Photos (metadati + immagine) | card con luogo Google, cache di sessione | 1 metadati per card visibile + 1 immagine per foto mostrata | 10 / 80 |
| Foto bucket list | web/amaterasu_bucket_photos.js | per card visibile | 5 / 40 |
| Geocoding | web/amaterasu_maps_bridge.js | creazione viaggio | 0 / 2 |

Note:
- Le foto sono il costo più alto: oggi la card chiede i metadati e
  carica la prima immagine; il carosello carica le altre solo se si
  scorre. Tappa 1b: una sola richiesta per card, foto 2-5 solo dentro il
  carosello aperto al tocco.
- Le cache sono in memoria per la sessione: ricaricando la pagina le
  richieste si ripetono.
- Soglie gratuite (Google, dal 2025): 10.000 richieste al mese per ogni
  SKU "Essentials", 5.000 per gli "Pro", 1.000 per gli "Enterprise"
  (contatti). Da verificare nella pagina prezzi prima di fissare le
  quote.

## 2. Altre chiamate esterne
| Servizio | Dove | Quando | Costo |
|---|---|---|---|
| Frankfurter (cambi BCE) | app: budget_fx_service.dart (cache in memoria); server: budget-fx-helpers.ts | spese in valuta diversa | gratuito, nessuna chiave |
| Google Drive API (scope drive.file) | archivio del viaggio | creazione viaggio e impostazioni | gratuito (quota per progetto ampia) |
| Google Sign-In / Firebase Auth | accesso | login | gratuito (Spark/Blaze) |

## 3. Firebase
| Voce | Dove | Letture per sessione (normale / peggiore) |
|---|---|---|
| Ascoltatore elenco viaggi | I miei viaggi | 5 / 30 |
| Documento viaggio + membri | workspace | 6 / 15 |
| Ogni sezione aperta (alloggi, trasporti, …) | un ascoltatore per sezione, attivo solo con la pagina aperta | 10 per sezione / 200 |
| Spese condivise e personali | pagina spese | 40 / 400 |
| Rimborsi e revisioni | dettagli spesa | 5 / 50 |
| Esportazione spese | solo al tocco | 0 / 1 lettura per spesa |
| Cloud Functions callable (32) | budget, inviti, gestione | 5 / 30 invocazioni |

Quote gratuite (Blaze con livello gratuito): Firestore 50.000 letture,
20.000 scritture e 20.000 eliminazioni al giorno; Functions 2 milioni di
invocazioni al mese; Hosting 10 GB di traffico al mese. Con 20 utenti
attivi al giorno nel caso peggiore: circa 20 x 1.000 = 20.000 letture
al giorno, sotto la soglia.

## 4. Quote da impostare nella console Google Cloud (proposta)
Per restare nei livelli gratuiti anche se la chiave venisse abusata:
| API / SKU | Quota giornaliera proposta | Motivo |
|---|---|---|
| Maps JavaScript API (Map loads) | 300 al giorno | ~9.000 al mese < 10.000 gratuite |
| Places API (New): Autocomplete | 300 sessioni al giorno | < 10.000 al mese |
| Places API (New): Place Details Essentials | 300 al giorno | < 10.000 al mese |
| Places API (New): Place Details Enterprise (telefono, sito, orari e prezzo dalla 1.29.0) | 30 al giorno | < 1.000 al mese; "Orari e prezzi" usa la stessa richiesta dei contatti (solo al tocco, in cache per la sessione) |
| Places API (New): Place Photos | 300 al giorno | < 10.000 al mese (se la soglia foto è 1.000 al mese: 30 al giorno) |
| Geocoding API | 100 al giorno | uso raro |
| Weather API (se mai attivata) | 0 finché non approvata | |
Inoltre: budget di fatturazione a 5 euro con avvisi al 50 %, 90 % e
100 %; restrizione della chiave ai referrer amaterasutrip.web.app e
amaterasutrip.firebaseapp.com e alle sole API usate.

Con le quote raggiunte, Google risponde con errore: l'app mostra già il
segnaposto (foto) o il messaggio "ricerca non disponibile", quindi la
funzione si limita ma non si blocca.
