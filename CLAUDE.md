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
Flutter (lib/) + Firebase: Firestore, Cloud Functions
(functions/), Hosting (hosting/). Test delle regole in
rules-tests/. Documentazione e stati in docs/.

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
- Dopo ogni modifica, esegui analisi e test se esistono.

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

Colori usati nelle schermate (scritti direttamente nei file,
non in AmaterasuColors):
- Testo principale crema #F2E7D5
- Testo secondario #B7A99B (più tenue: #9E9287)
- Sfondi scuri #100C0A, #1A1512, #1A1310, #241A16
- Bordi #3A2A20, #5A3023
- Accenti arancio: #D96C32 (budget e viaggi), #E28A32
  (impostazioni), poi #E3A66C, #E86A3A, #E17A43
Le nuove schermate devono usare questi stessi valori.

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
- Workspace del viaggio
  (lib/features/trips/presentation/pages/workspace/widgets/):
  TripWorkspaceShell, TripWorkspaceHeader,
  TripWorkspaceBottomBar, TripWorkspaceCard e
  TripPlaceholderPage (pagina segnaposto per le sezioni
  non ancora sviluppate).
- lib/features/trips/presentation/widgets/: TripCard,
  TripSectionTitle (titolo con icona e colore di accento),
  foglio per scegliere la copertina.
- Budget (lib/features/trips/budget/presentation/):
  BudgetDialogChrome (stile dei dialoghi), BudgetMoneyInput
  (inserimento importi), BudgetTravelerAvatar.

Cose da sapere sullo stile:
- AmaterasuColors, AmaterasuSpacing e AmaterasuRadius sono
  poco usati. La maggior parte delle schermate scrive i
  colori direttamente nel codice (circa 630 volte). Da
  valutare nell'audit.
- I file del tema vengono importati con la "A" maiuscola
  (Amaterasu_colors.dart), mentre il file vero è
  amaterasu_colors.dart. Su Windows funziona lo stesso,
  ma su macOS e Linux potrebbe dare errore. Da valutare
  nell'audit.

## Stato del progetto
Ricostruito dalla cronologia dei commit (fino a novembre
2026) e dal codice in lib/features.

Finito:
- Accesso e account: email e password, Google, verifica
  email, logout, "ricordami" (auth).
- Profilo utente con QR (profile).
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
  raggruppamento per giorno (B8.4-B8.7). Ultimo commit:
  B8.4-B8.7. Resta da stabilire cosa manca per
  considerarlo finito.

Da sviluppare (oggi sono solo pagine segnaposto):
- Itinerario
- Mappa
- Viaggiatori (pagina del workspace)
- Prenotazioni
- Hotel
- Ristoranti
- Trasporti
- Luoghi salvati
- Note
- Shopping
- Ricordi

La cartella docs/ contiene solo privacy.html. Non ci sono
documenti sullo stato del progetto.

## Dopo il budget
Finita la sezione budget e spese, eseguire un audit in sola
lettura (file, duplicati, codice morto, regole, sicurezza)
e proporre un report prima di modificare qualsiasi cosa.