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
- Workspace del viaggio
  (lib/features/trips/presentation/pages/workspace/widgets/):
  TripWorkspaceShell, TripWorkspaceBottomBar e
  TripPlaceholderPage (pagina segnaposto per le sezioni
  non ancora sviluppate). TripWorkspaceHeader e
  TripWorkspaceCard esistono ma oggi nessuna pagina li usa.
- lib/features/trips/presentation/widgets/: TripCard,
  TripSectionTitle (titolo con icona e colore di accento),
  foglio per scegliere la copertina.
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
  avviso di date sovrapposte; editor a sezioni (luogo
  Google che compila anche telefono e sito, tipo, contatti,
  date e orari, stato, prenotazione, ospiti, note);
  eliminazione per creatore o OWNER, spesa condivisa
  creata o collegata dalla card. I dati Google extra degli
  alloggi passano da web/amaterasu_stay_places.js (separato
  dal ponte della bucket list). Dati in
  trips/{tripId}/stays scritti dall'app con regole in
  firestore.rules; esclusi dalla duplicazione del viaggio.
  L'importo mostrato è quello della spesa collegata (nel
  soggiorno non c'è un campo importo).
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
- Prenotazioni
- Ristoranti
- Trasporti
- Luoghi salvati
- Note
- Shopping
- Ricordi

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
- Esportazione del riepilogo spese in PDF o CSV.