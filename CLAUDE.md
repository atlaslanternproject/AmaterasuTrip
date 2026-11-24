# Amaterasu Trip

## Cos'è
Amaterasu Trip è una piattaforma per organizzare e gestire
un viaggio. NON usa AI per generare itinerari: è uno spazio
dove l'utente scrive, crea attività e raccoglie tutto ciò
che riguarda il suo viaggio.

Un "viaggio" può essere qualsiasi cosa: una vacanza, un
weekend fuori, un'uscita di un giorno. Dentro ci stanno
biglietti, mappe, attività, budget, note e altro.

## Stack
Flutter (lib/) + Firebase: Auth, Firestore, Storage, App
Check, Cloud Functions (functions/), Hosting (hosting/).
Test delle regole in rules-tests/. Documentazione e stati
in docs/ e nel README.

## Chi sono
Principiante con Flutter e Firebase. Rispondi sempre in
italiano.

## Come lavorare
- Fai tu le modifiche e spiega in breve cosa hai fatto e perché.
- Evita gergo tecnico non necessario.
- Priorità attuale: finire le funzioni mancanti.
- Una funzione alla volta, con modifiche piccole e verificabili.

## Regole di sicurezza
- Prima di modifiche grandi, ricordami di fare commit.
- Lavora su un branch, mai direttamente su main.
- Non fare deploy su Firebase senza chiedermelo.
- Non toccare firestore.rules senza spiegarmi l'impatto.
- Non inserire mai chiavi, .env o credenziali nel codice.
- Dopo ogni modifica, esegui analisi e test se esistono:
  `bash tool/check_all.sh` li esegue tutti (analisi, test
  Flutter, traduzioni, lint e build functions, test node,
  3 test del budget con gli emulatori).

## Cosa non si tocca
- Le funzioni già approvate (gestione viaggio, impostazioni,
  bucket list) non vanno cambiate né rifatte senza che io
  lo chieda esplicitamente.
- Lo stile grafico attuale va mantenuto: colori, font,
  spaziature, componenti e look generale. Le nuove schermate
  devono sembrare parte della stessa app.
- Prima di creare un nuovo componente grafico, cerca se ne
  esiste già uno simile in lib/ e riutilizzalo.
- Se una modifica richiede di toccare qualcosa di approvato,
  fermati e chiedimelo prima.
- Eccezione: puoi riordinare la struttura (spostare,
  rinominare o dividere file, creare moduli condivisi,
  sostituire valori scritti a mano con i token del tema)
  anche nelle parti approvate, purché comportamento e
  aspetto restino identici e tutti i controlli passino.
  Spiegami sempre cosa hai spostato.

## Regole fisse v2 (verso la 2.0.0)
Obiettivo: arrivare alla 2.0.0 come base definitiva (dopo solo
extra e correzioni), utile prima, durante e dopo il viaggio,
facile e rassicurante ("so da dove partire").

1. VALUTARE PRIMA DI MODIFICARE. Prima di creare o cambiare un
   componente, una schermata, un dialogo, un campo o una
   funzione, cerca se esiste già qualcosa di simile e scrivi in
   docs/PROGRESS-sezioni.md una valutazione in 3 righe:
   (a) esiste già? (b) conviene modificarlo, estrarlo in un
   modulo condiviso o unificarlo in un modulo unico? (c) cosa
   tocca e quali test servono. Riusa in modo IDENTICO, mai
   varianti nuove. Se sta in un modulo approvato si estrae senza
   cambiarne il comportamento, con test prima e dopo.
2. Nomi delle persone: sempre lo USERNAME (es. "Yato"), mai il
   nome completo né le sole iniziali, ovunque, con un'unica
   funzione condivisa.
3. Costi sotto 5 euro al mese (idealmente 0): nessuna chiamata
   esterna in cicli o per ogni card; ricerche e Audit Trail a
   pagine e su richiesta; niente ascoltatori Firestore sempre
   attivi se non servono; meteo, cambi e info paese con cache
   condivisa per viaggio e scadenza; foto e contatti Google solo
   quando servono e mai salvati; ogni nuova API esterna va
   dichiarata con i suoi limiti in docs/audit/API-ESTERNE.md. Se
   un limite è inevitabile: funzione limitata, non bloccata.
4. Grafica: docs/design/DIRETTIVE-UI.md. Nessun banner
   decorativo. Restano la copertina del viaggio (I miei viaggi e
   testa della home del viaggio) e la foto del luogo in testa
   alle card delle sezioni, senza cambiarne l'aspetto. Icona
   diversa per ogni sezione, stesso colore di accento.
5. Decisioni fisse: nessuna AI, nessuna notifica, nessun
   offline, nessun nucleo familiare, nessun saldo semplificato,
   nessun documento sensibile nel database, nessun registro
   errori né statistiche d'uso; solo web (Android deprecato);
   l'app non è un navigatore (i percorsi aprono Google Maps);
   solo tema scuro; solo i ruoli OWNER e TRAVELER; API esterne
   gratuite benvenute se dichiarate.
6. Moduli approvati (bucket list, budget, gestione viaggio,
   impostazioni, alloggi): nessun cambio di funzioni, dati o
   regole oltre quanto scritto nel prompt v2. Il loro aspetto
   cambia solo dopo l'ok sulla tabella docs/audit/COERENZA.md.
7. Release: a ogni rilascio si aggiorna anche il file delle
   novità (it/en) per la nuova versione (tappa A del prompt v2).

## Convenzioni del codice
- File piccoli: obiettivo sotto le 200 righe, un solo
  compito per file. Per dividere una schermata senza
  cambiarne la logica si usano i file `part` con
  `extension` sulla classe State (es. budget_create_dialog.dart
  e budget_create_dialog_save.dart), come nella bucket list.
- Intestazione: ogni file Dart scritto da noi inizia con
  2-4 righe di commento in italiano che spiegano cosa fa
  il file (anche i nuovi file e i file `part`). I file
  generati (lib/l10n/app_localizations*.dart,
  lib/firebase_options.dart) non si toccano.
- Moduli condivisi: se lo stesso codice serve in più
  file, va in un modulo dedicato invece di essere copiato
  (es. budgetL10n in budget_l10n.dart, requireVerifiedUid in
  functions/src/shared/).
- Token del tema: colori, spaziature e raggi si prendono
  da AmaterasuColors, AmaterasuSpacing e AmaterasuRadius.
  Se serve un valore nuovo usato in più punti, si aggiunge
  un token; i valori usati una sola volta possono restare
  nel file.
- Testi: tutti i testi visibili in lib/l10n (app_it.arb e
  app_en.arb), mai scritti nel codice. Chiavi nuove con il
  prefisso dell'area e `traveler` all'americana.
- Cloud Functions: una funzione per file, riesportata da
  functions/src/index.ts con lo stesso nome.
- `// TODO(audit): ...` segna punti da migliorare trovati
  nell'audit (vedi docs/audit/AUDIT.md).

## Stile grafico
Tema scuro, toni caldi (nero-bruno, crema, arancio/rosso).
Ricavato da lib/core/theme e dai colori usati davvero nelle
schermate.

Tema (lib/core/theme/):
- app_theme.dart: Material 3, scuro, colore base primary.
- AmaterasuColors: background #1A0B08, backgroundSecondary
  #3A120D, primary #E5482E, card bianco 5%, border bianco
  15%, success #3DBE6C, error #E25555.
- AmaterasuSpacing: xs 4, sm 8, md 16, lg 24, xl 32, xxl 48.
- AmaterasuRadius: sm 8, md 14, lg 24.

Tavolozza delle schermate (token in AmaterasuColors, stessi
valori che prima erano scritti a mano):
- Testi: textPrimary crema #F2E7D5, textSecondary #B7A99B,
  textMuted #9E9287 (più varianti textCream, textWarm…)
- Sfondi: surfaceDeep #100C0A, surface #1A1512,
  surfaceWarm #1A1310, surfaceRaised #241A16, surfaceCard…
- Bordi: borderWarm #3A2A20, borderAccent #5A3023,
  borderStrong #49352A
- Accenti: accentBudget #D96C32 (budget e viaggi),
  accentSettings #E28A32 (impostazioni), accentGold
  #E3A66C, accentFlame #E86A3A, accentOrange #E17A43
Le nuove schermate devono usare questi token.

Font: nessun font personalizzato, si usa quello di sistema
di Material. Solo il titolo della panoramica viaggio usa
'serif'. Le dimensioni più usate sono 12, 13, 14 e 15 per
il testo, 16-18 per i titoli di sezione e 20-24 per i
titoli grandi.

Forme: angoli arrotondati da 12 a 20 (i più usati 12, 14,
16, 18). Bottone principale alto 56.

Componenti riutilizzabili:
- lib/core/widgets/: AmaterasuBackground (sfondo sfumato),
  AmaterasuCard, AmaterasuPrimaryButton, AmaterasuTextField,
  AmaterasuPasswordField, AmaterasuDivider,
  AmaterasuSettingsCard (card espandibile per impostazioni),
  dialogo modifiche non salvate, AmaterasuBottomBar,
  AmaterasuGlobalShell, bottoni Google e Discord.
- lib/core/links/: AmaterasuWebLink (validazione link come
  la bucket list, indirizzo Google Maps), AmaterasuLinkOpener
  (nuova scheda, "Copia link" se non si apre, Google Maps con
  errore), AmaterasuLinkChip. Da usare per ogni nuovo link;
  la bucket list ha ancora la sua copia (TODO(audit)).
- lib/core/places/ (modulo Luogo condiviso): ricerca
  Google (AmaterasuPlaceSearchField, amaterasuPlaceSearchProvider),
  contatti e foto con cache di sessione (amaterasuPlaceInfoProvider,
  web/amaterasu_place_info.js), carosello foto, pop-up
  "Contatta", riempimento automatico di telefono e sito,
  controllo telefono/email. Da usare in ogni sezione con
  luoghi; la bucket list ha ancora i suoi (TODO(audit)).
- Workspace del viaggio
  (lib/features/trips/presentation/pages/workspace/widgets/):
  TripWorkspaceShell, TripWorkspaceBottomBar e
  TripPlaceholderPage (pagina segnaposto per le sezioni
  non ancora sviluppate). TripWorkspaceHeader e
  TripWorkspaceCard esistono ma oggi nessuna pagina li usa.
- lib/features/trips/presentation/widgets/: TripCard,
  TripSectionTitle (titolo con icona e colore di accento),
  foglio per scegliere la copertina.
- Sezioni del viaggio (lib/features/trips/sections/,
  modulo comune delle nuove sezioni): TripSectionStore
  (Firestore in trips/{tripId}/{collezione}, campi vuoti tolti
  in modifica), TripSectionCodec, TripSectionFields (limiti
  come le regole), TripSectionPlace (luogo con prefisso),
  TripBookingStatus; viste TripSectionCard /
  TripSectionCompactCard / TripSectionDetailsRow costruite da
  un TripSectionEntry, TripSectionList, TripSectionScaffold,
  TripSectionToolbar (filtri e vista ricordata con
  TripSectionViewMemory), spesa collegata
  (TripSectionExpenseTarget, footer e pulsante), conferma di
  eliminazione, editor (TripSectionEditorFrame, blocchi,
  giorno/ora, scelte, viaggiatori, costo, luogo). Nelle regole
  le funzioni section* valgono solo per i nuovi blocchi; test
  in rules-tests/sections. Nuove sezioni: usare questo modulo.
  Limite delle regole: al massimo 1000 operazioni per controllo;
  nei blocchi con molti campi: controlli leggeri per primi, testi
  in linea, campi rari raggruppati in una mappa (es. extras dei
  trasporti).
- Budget (lib/features/trips/budget/presentation/):
  BudgetDialogChrome (stile dei dialoghi), BudgetMoneyInput
  (inserimento importi), BudgetTravelerAvatar, budgetL10n
  (testi del budget nella lingua scelta).

Cose da sapere sullo stile:
- I colori usati almeno 3 volte sono token; i colori usati
  1-2 volte restano scritti nel file che li usa.
- Gli import vanno scritti con il nome vero del file, tutto
  minuscolo (amaterasu_colors.dart): su macOS e Linux le
  maiuscole contano.

## Stato del progetto
Ricostruito dalla cronologia dei commit (fino a novembre
2026) e dal codice in lib/features.

Finito:
- Accesso e account: email e password, Google, verifica
  email, logout, "ricordami" (auth).
- Profilo utente (profile).
- Impostazioni globali: account, dati e cancellazione
  account, lingua, privacy, profilo, informazioni
  (settings). Approvate.
- Gestione del viaggio: creazione con destinazione (ricerca
  su mappa), valuta, copertina e archivio Google Drive;
  inviti, questionario e profili organizzativi dei
  viaggiatori; impostazioni del viaggio (informazioni,
  gestione, privacy, viaggiatori). Approvata.
- Panoramica del viaggio (overview) e struttura del
  workspace con barra di navigazione.
- Bucket list: attività condivise, voti, filtri, ricerca
  luoghi Google, controllo duplicati, richiesta di
  cancellazione con approvazione. Approvata.
- Hotel e alloggi (lib/features/trips/stays e
  pages/workspace/more/hotels): elenco con filtri (stato,
  tipo, prossimi/passati) e ordine per check-in; viste
  Card, Elenco e Dettagli come la bucket list (scelta
  ricordata nelle preferenze locali; Mappa, Spesa,
  Contatta e Modifica in ogni vista); card nello
  stile della bucket list con carosello di foto Google (max
  5, chieste solo quando la card appare, cache in memoria
  per la sessione, mai salvate), tipo di alloggio, stato,
  riquadro check-in/notti/check-out, prenotazione, link,
  Mappa, "Contatta" (telefono, email, sito) e ospiti;
  avviso di date sovrapposte e avviso (solo informativo)
  delle notti del viaggio senza alloggio; cancellazione
  gratuita con data ben visibile (colore di avviso negli
  ultimi 3 giorni), servizi inclusi (colazione, parcheggio,
  Wi-Fi, cucina), "come arrivare" e costo previsto; editor
  a sezioni (luogo Google che compila anche telefono e sito,
  tipo, contatti, date e orari, stato, prenotazione, costo e
  cancellazione, servizi e come arrivare, ospiti, note);
  eliminazione per creatore o OWNER, spesa condivisa
  creata o collegata dalla card. Luogo, foto e contatti
  vengono dal modulo condiviso lib/core/places. Dati in
  trips/{tripId}/stays scritti dall'app con regole in
  firestore.rules; esclusi dalla duplicazione del viaggio.
  L'importo speso è quello della spesa collegata; il costo
  previsto (facoltativo, importo e valuta) è solo una stima
  e diventa il valore di partenza di "Crea spesa".
- Trasporti (lib/features/trips/transports e
  pages/workspace/more/transport): tipo (volo, treno, bus,
  traghetto, noleggio auto, transfer, altro), da/a con luogo
  Google, partenza e arrivo con data, ora e fuso orario,
  compagnia, numero, codice, posti, passeggeri, prenotato su,
  link, stato, note, costo previsto e spesa collegata
  (categoria transport); filtri (stato, tipo, prossimi/
  passati, ordine), tre viste ricordate; avviso solo
  informativo per coincidenze sotto l'ora e arrivi dopo la
  partenza successiva. Dati in trips/{tripId}/transports.
- Le sezioni nuove (transports, reservations, restaurants,
  savedPlaces, notes, shoppingItems, packingItems, memories)
  sono escluse da duplicateTrip; deleteTrip le cancella come
  sottoraccolte.
- Prenotazioni (lib/features/trips/reservations e
  pages/workspace/more/bookings): nome, categoria (biglietto,
  ingresso, tour, escursione, altro), stato, data e ora,
  luogo Google con foto, codice, link, partecipanti, regole
  di cancellazione, note, costo previsto e spesa collegata
  (categoria activities); filtri, tre viste ricordate. Dati
  in trips/{tripId}/reservations.
- Ristoranti (lib/features/trips/restaurants e
  pages/workspace/more/restaurants): luogo Google con foto
  (compila anche telefono e sito), cucina, fascia di prezzo
  (€-€€€€), stato (da provare, prenotato, provato),
  prenotazione (data, ora, persone), voti dei viaggiatori
  SS/S/A/B come nella bucket list ma senza toccarla (campo
  votes: ognuno cambia solo il proprio, garantito dalle
  regole), note, costo previsto e spesa collegata (categoria
  food); filtri, ordine per voti/nome/prenotazione, tre viste.
  Dati in trips/{tripId}/restaurants.
- Luoghi salvati (lib/features/trips/saved_places e
  pages/workspace/more/saved_places): luogo cercato su Google
  (con foto) oppure link di Google Maps incollato (da cui si
  ricavano nome e coordinate se presenti), categoria (da
  vedere, mangiare, shopping, natura, vita notturna, altro),
  note, "aggiunto da"; filtro per categoria, ordine per nome,
  tre viste. Nessuna spesa. Dati in trips/{tripId}/savedPlaces.
- Note (lib/features/trips/notes e pages/workspace/more/notes):
  titolo, testo, condivise o private (le private le leggono,
  modificano ed eliminano solo gli autori: regole e test; l'app
  legge con due richieste, condivise + proprie private), fissate
  in alto, checklist con voci spuntabili anche dalla card,
  modello "Info utili" (Wi-Fi, numeri di emergenza…); filtro
  condivise/private, tre viste. Dati in trips/{tripId}/notes.
- Shopping (lib/features/trips/shopping e
  pages/workspace/more/shopping): Acquisti (cosa,
  per chi, dove, budget stimato, comprato, prezzo reale, note,
  spesa collegata categoria shopping che parte dal prezzo reale o
  dal budget); spunta dalla card, filtri, tre viste. Dati in
  trips/{tripId}/shoppingItems. La vecchia Valigia (packingItems)
  si importa nella Checklist.
- Checklist (lib/features/trips/checklists e
  pages/workspace/more/checklists): più liste per viaggio,
  modelli pronti (Valigia, Documenti, Prima di partire, Prima di
  uscire di casa, Farmaci e igiene, Elettronica, Vuota),
  condivise o personali (solo l'autore: regole e test), categorie
  a tendina con barra, voci in linea con quantità e assegnatario,
  filtri da fare/fatte e persona, azzera, duplica, riordino,
  stampa e CSV. Le voci stanno nella lista (campo items) e si
  cambiano una alla volta. Dati in trips/{tripId}/checklists.
- Ricordi (lib/features/trips/memories e
  pages/workspace/more/memories): diario per giorno (data,
  valutazione 1-5 stelle, il momento del giorno, testo, autore)
  e link agli album esterni con il modulo link; nessuna foto su
  Firebase; filtro diario/album, tre viste. Dati in
  trips/{tripId}/memories.
- Tolti di proposito: notifiche (ottobre 2026) e cifratura
  E2EE dei dati sanitari, sostituita dai profili
  organizzativi.

In corso:
- Budget e spese (lib/features/trips/budget e la pagina
  spese del workspace). Già fatti: spese con più pagatori,
  revisioni con approvazione, rimborsi, categorie e
  dashboard, più valute con cambio, budget personale
  privato (B7.1-B7.4), metodi di pagamento (B7.5, B8.3),
  ordinamento e formato importi (B8.1), visualizzazione
  unica delle valute (B8.2), storico spese e
  raggruppamento per giorno (B8.4-B8.7). Rilasciato con la
  versione 1.10.0+12. Poi "segna come pagato" dichiarato
  dal creditore, con annullamento (novembre 2026). Resta da
  stabilire cosa manca per considerarlo finito.

Da sviluppare (oggi sono solo pagine segnaposto):
- Itinerario
- Mappa
- Viaggiatori (pagina del workspace)

Documentazione: README.md (avvio, struttura, test,
pubblicazione); docs/ contiene privacy.html, la checklist
delle prove manuali del budget e l'audit di manutenibilità
(docs/audit/AUDIT.md con le voci risolte e aperte,
docs/audit/PROGRESS.md con i passi fatti).

## Audit
L'audit di manutenibilità dopo il budget è stato fatto sul
branch chore/audit-manutenibilita (novembre 2026). Le voci
non risolte (regole Storage, cancellazione account lato
server, file con build lunghi, testi _t(...) della bucket
list, aggiornamenti maggiori dei pacchetti) sono in
docs/audit/AUDIT.md.

## Roadmap e decisioni
Decise (novembre 2026):
- Piattaforma principale: il Web. Android è deprecato:
  resta nel progetto, ma non lo proviamo né lo rilasciamo.
- Niente inserimento offline.
- Niente "sollecita" e nessuna notifica.
- Niente gestione dei nuclei familiari.
- Niente saldo semplificato dei debiti: i rimborsi restano
  debito per debito.

Da fare nel modulo spese:
1. "Segna come pagato" dichiarato dal creditore. Fatto.
2. Ricevute allegate: pulsante facoltativo "Allega" con
   file, foto o link, salvati su Google Drive.

A fine programmazione:
- Audit finale di coerenza tra i moduli.
- Spese collegate a ristoranti e prenotazioni (per gli
  alloggi è già fatto).
- Esportazione del riepilogo spese in PDF o CSV: fatta nella
  1.23.0 (pulsante nella pagina spese, solo lettura).