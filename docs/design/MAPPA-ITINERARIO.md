# Mappa e Itinerario: documento di progetto (tappa L)

Scritto il 25/11/2026. Solo documento: si costruisce dopo il tuo ok.
Oggi Itinerario e Mappa sono pagine segnaposto
(workspace/itinerary/trip_itinerary_page.dart, workspace/map/
trip_map_page.dart). Decisioni fisse che valgono qui: nessuna AI, nessun
navigatore (i percorsi aprono Google Maps), nessuna API di percorso,
nessun banner, solo tema scuro, costi sotto 5 €/mese.

## 1. Itinerario: cosa contiene
- Compaiono **solo** le voci inserite nell'itinerario (non tutto il
  viaggio).
- Una voce è:
  - un **riferimento** a un elemento esistente: alloggio, trasporto,
    prenotazione, ristorante, luogo salvato, attività della bucket list;
  - una **voce libera** (titolo, nota, ora facoltativa, luogo facoltativo);
  - una **giornata libera** (blocco che occupa il giorno o mezza giornata).
- "Previsto X, fatto invece Y": ogni voce conserva la proposta e, se
  serve, cosa si è fatto davvero (un altro riferimento o un testo), senza
  perdere la proposta. Esempio: previsto "Tempio X", fatto "cena al
  ristorante Tizio".
- Aggiungere dall'itinerario qualcosa di nuovo (un ristorante, un luogo):
  l'elemento nasce anche nella sua sezione con i dati essenziali (stesso
  editor/codec della sezione), e la voce lo richiama. La modifica resta
  sincronizzata perché la voce non copia i dati: li legge dall'elemento.

### Dati (proposta)
`trips/{tripId}/itinerary/{itemId}`:
- `day` (AAAA-MM-GG), `time` (HH:MM, facoltativo), `order` (intero per
  il riordino a mano), `kind` (`ref` | `free` | `freeDay`);
- `ref`: `{section, id}` per i riferimenti (stesse sigle di Cerca);
- `title`, `note`, `place` (TripSectionPlace) per le voci libere;
- `actual`: `{ref?, text?}` per "fatto invece";
- `zone`: zona salvata (vedi 3), `createdByUid`, `createdAt`,
  `updatedAt` (e `updatedByUid` se si sceglie l'Audit Trail A/B/C).
- Regole con il modulo comune delle sezioni (sectionBase, sectionPlace,
  controlli leggeri per primi); test in rules-tests/sections.
- Esclusa dalla duplicazione del viaggio solo se lo decidi (un
  itinerario potrebbe servire come modello: da valutare).
- Un riferimento a un elemento cancellato mostra "Elemento eliminato"
  con la possibilità di toglierlo.

## 2. Tre viste dell'Itinerario
1. **Linea del tempo continua** (predefinita prima del viaggio): una lista
   unica di tutto il viaggio in ordine, intestazione per giorno, filtri
   con il componente condiviso (sezione, persona, stato).
2. **Giorno per giorno** (predefinita durante il viaggio): striscia dei
   giorni in alto, il giorno di oggi selezionato.
3. **Mappa** (le voci dell'itinerario del giorno o del periodo scelto).
- Scelta della vista ricordata con TripSectionViewMemory.

### Raggruppamento per zona in ogni vista
- Lista e giorno per giorno: dentro ogni giorno le voci sono raggruppate
  per zona anche se in orari diversi; gruppo apribile, gruppi in ordine
  di orario della prima voce, dentro il gruppo ordine di orario (poi
  `order`).
- Mappa: i pin si raggruppano; toccando un gruppo si aprono le zone e poi
  le singole voci.
- Struttura pronta per il futuro "proponi di sistemare l'itinerario per
  zona" (solo annotato, non costruito): basta `zone` su ogni voce e
  l'ordine per giorno; nessun dato in più.

## 3. Da dove vengono le zone (nessuna chiamata in più)
In ordine: (1) `area` già scritta dall'utente (luoghi salvati);
(2) quartiere dai componenti dell'indirizzo di Google (`sublocality` o
`neighborhood`), chiesti nella **stessa** richiesta che già si fa quando si
sceglie un luogo (il ponte web/amaterasu_maps_bridge.js li chiede già per
la destinazione; per il modulo dei luoghi va aggiunto il campo alla
richiesta esistente: da verificare che non cambi la categoria di prezzo,
vedi API-ESTERNE.md); (3) città (`city` degli alloggi, `zoneCity` di
prenotazioni e ristoranti, città dei trasporti); (4) "Senza zona".
La zona si salva sulla voce al momento dell'inserimento e si può
cambiare a mano.

## 4. Mappa (pagina Mappa)
- Mostra **tutte** le cose con posizione di ogni sezione (non solo
  l'itinerario): alloggi, trasporti (partenza/arrivo), prenotazioni,
  ristoranti, luoghi, bucket list.
- Filtri con il componente condiviso: sezione, giorno, stato, persona.
- Pin e gruppi con l'icona della sezione (stessa icona e colore di
  accento delle sezioni), **senza foto**; riquadro del luogo selezionato
  in basso con miniatura quadrata, nome, sezione, orario e azioni
  (Apri la sezione, Apri su Maps).
- Linea tratteggiata tra le voci del giorno in ordine cronologico, **solo
  estetica** (nessun calcolo di percorso).
- "Apri A→B su Maps": link di Google Maps con origine e destinazione, a
  piedi di default (AmaterasuLinkOpener.openMaps); nessuna API di
  percorso.
- Tecnica: google_maps_flutter già nel progetto (mappa della
  destinazione) con la chiave Maps già configurata; raggruppamento dei
  pin fatto in Dart (griglia per livello di zoom), senza librerie nuove.
- Costi: 1 caricamento della mappa per apertura (Maps JavaScript API,
  quota in COSTI.md: 300 al giorno impostati); dati letti una volta per
  apertura con gli store delle sezioni.

## 5. Tra due tappe
- Distanza in linea d'aria (formula dell'emisenoverso, nessuna API), in
  km o miglia secondo Aspetto (E5).
- Pulsante "Apri percorso a piedi" su Google Maps.

## 6. Altre funzioni
- Avvisi solo informativi: sovrapposizioni di orario nello stesso giorno
  e buchi (giorni senza voci, come le notti senza alloggio).
- Trascina per riordinare (aggiorna `order` della voce spostata e delle
  vicine, in un solo batch).
- "Condividi il programma del giorno" come testo (orari, nomi, indirizzi,
  link di Maps) con share_plus, già nel progetto (WhatsApp e simili).
- Link con il modulo "Link utili" (TripSectionLinks).
- Liste: voci compatte con **miniatura quadrata** (foto del luogo se c'è,
  altrimenti icona della sezione); niente foto larghe nelle liste
  dell'itinerario; stile, icone e colori come nelle altre sezioni.

## 7. Ordine di costruzione proposto (un rilascio per passo)
1. Dati e regole dell'itinerario, linea del tempo con voci libere e
   riferimenti.
2. Giorno per giorno, raggruppamento per zona, riordino, avvisi.
3. "Aggiungi nuovo dall'itinerario" (crea anche nella sezione).
4. Previsto/fatto, condividi il giorno.
5. Pagina Mappa con filtri, gruppi e riquadro; vista Mappa
   dell'Itinerario; distanza e "Apri su Maps".

Moduli approvati: alloggi e bucket list vengono solo **letti** (i
riferimenti non li cambiano); "aggiungi nuovo" crea solo ristoranti e
luoghi (sezioni nuove). Nessuna nuova API, nessuna nuova funzione sul
server.
