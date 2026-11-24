# Avanzamento delle sezioni (lavoro a tappe)

Regole: un branch per tappa da main, un commit per passo,
`bash tool/check_all.sh` dopo ogni passo, poi release come la
1.13.0 (merge --no-ff, minor +1 e build +1, tag, push, regole
prima se cambiate, functions solo se cambiate, build web,
pagine di hosting/, deploy hosting, verifiche). Se un passo
fallisce ci si ferma. Ripartendo da una sessione nuova si
riprende dalla prima tappa non finita.

| Tappa | Stato | Branch | Versione |
|---|---|---|---|
| 0. Modulo Luogo condiviso (lib/core/places) | fatta, pubblicata il 22/11/2026 | feature/luogo-condiviso (eliminato) | 1.14.0+18 |
| 1. Hotel e alloggi, migliorie | fatta, pubblicata 1.15.0 il 22/11/2026 | feature/alloggi-migliorie | 1.15.0+19 |
| 2. Trasporti | fatta, pubblicata 1.16.0 il 23/11/2026 | feature/trasporti | 1.16.0+20 |
| 3. Prenotazioni | fatta, pubblicata 1.17.0 il 23/11/2026 | feature/prenotazioni | 1.17.0+21 |
| 4. Ristoranti | fatta, pubblicata 1.18.0 il 23/11/2026 | feature/ristoranti | 1.18.0+22 |
| 5. Luoghi salvati | fatta, pubblicata 1.19.0 il 23/11/2026 | feature/luoghi-salvati | 1.19.0+23 |
| 6. Note | fatta, pubblicata 1.20.0 il 23/11/2026 | feature/note | 1.20.0+24 |
| 7. Shopping e valigia | fatta, pubblicata 1.21.0 il 23/11/2026 | feature/shopping | 1.21.0+25 |
| 8. Ricordi | fatta, pubblicata 1.22.0 il 24/11/2026 | feature/ricordi | 1.22.0+26 |
| 9. Spese, esportazione CSV/PDF | fatta, pubblicata 1.23.0 il 24/11/2026 | feature/esporta-spese | 1.23.0+27 |
| 10. Analisi Drive e budget per categoria | fatta (solo analisi) | docs/analisi-drive-budget | - |

## Tappa 0 - Modulo Luogo condiviso

Commit:
- b01569b refactor(places): dati del luogo in lib/core/places
  (contatti, foto, cache, ponte JS web/amaterasu_place_info.js,
  provider di ricerca, controllo telefono/email).
- 1af6285 refactor(places): ricerca, carosello foto, pop-up
  Contatta e riempimento automatico condivisi; gli alloggi li
  usano con gli stessi 57 test di prima.
- c8a3cc9 docs: CLAUDE.md e questo file.
- c9fce93 release 1.14.0+18 (tag v1.14.0). Regole e functions
  invariate. Pubblicato l'hosting il 22/11/2026 con tutte le
  verifiche passate (pagine, version.json, manifest, .well-known,
  32 funzioni attive). La prima build era fallita per una cache
  vecchia in .dart_tool/flutter_build (plugin tolti nell'audit):
  svuotata quella cartella, la build è riuscita. Codice invariato.

Prove da fare sul sito (Hotel e alloggi deve funzionare come prima):
1. Nuovo alloggio: cerca un hotel su Google e sceglilo; nome,
   indirizzo, telefono e sito si compilano.
2. Scegli un secondo hotel: telefono e sito cambiano.
3. Sulla card scorri le foto e vedi gli autori.
4. Premi Contatta e prova Chiama, Scrivi, Apri e Copia.
5. Vista Elenco: foto piccola; vista Dettagli: nessuna foto.
6. Un alloggio senza luogo Google mostra il segnaposto con l'icona.

## Tappa 1 - Hotel e alloggi, migliorie

Commit:
- 4a739f5 docs: tappa 0 pubblicata.
- 6c9e9dd dati e regole: costo previsto (importo e valuta),
  cancellazione gratuita fino al, servizi inclusi, come
  arrivare; 5 campi facoltativi nuovi in firestore.rules (stays)
  con test in rules-tests/stays-rules.test.mjs.
- bfe24cf editor: sezioni "Costo e cancellazione" e "Servizi e
  come arrivare"; valuta predefinita = valuta del viaggio.
- 49c02ae viste: costo, servizi, come arrivare, etichetta della
  cancellazione gratuita (verde, rossa negli ultimi 3 giorni,
  spenta se passata); "Crea spesa" parte dal costo previsto.
- d040678 avviso solo informativo delle notti senza alloggio.
- Fuori programma: showTripStayEditor spostato in
  trip_stay_editor_dialog.dart (editor sotto le 200 righe).

Prove da fare sul sito:
1. Modifica un alloggio: scrivi un costo previsto, scegli la
   valuta e salva; la card mostra "Costo previsto".
2. Premi "Crea spesa": importo e valuta partono dal costo previsto.
3. Metti la cancellazione gratuita fra 10 giorni: etichetta verde.
4. Mettila fra 2 giorni: etichetta rossa con i giorni che
   mancano, anche in Elenco; in Dettagli compare l'icona di avviso.
5. Spunta colazione e Wi-Fi e scrivi "come arrivare": compaiono
   nella card.
6. Lascia una notte del viaggio senza alloggio: in cima compare
   l'avviso con la data; annullando un alloggio le sue notti
   diventano scoperte.
7. Togli costo, data e servizi: spariscono dalla card.
8. Su telefono la card e l'editor si leggono senza tagli.

## Tappa 2 - Trasporti

Commit:
- 7fb886e docs: tappa 1 pubblicata.
- 5a72938 modulo comune delle sezioni (lib/features/trips/sections),
  dati e regole dei trasporti (funzioni section* e blocco
  transports in firestore.rules, test in rules-tests/sections);
  tutte le sezioni nuove escluse da duplicateTrip (con test).
- 1cbba49 pagina Trasporti: tre viste ricordate, filtri, avvisi
  di coincidenza, editor, spesa collegata, eliminazione.
- Fuori programma: duplicateTrip esclude già anche le raccolte
  delle tappe 3-8, così le functions si pubblicano una volta.

Prove da fare sul sito:
1. Trasporti è vuota e invita ad aggiungere; premi "+".
2. Crea un volo: cerca l'aeroporto di arrivo su Google, metti
   orari e fusi orari, compagnia, numero, passeggeri e costo.
3. La card mostra percorso, partenza → arrivo con UTC e durata.
4. Crea un treno che parte 30 minuti dopo l'arrivo del volo:
   in cima compare l'avviso di coincidenza stretta.
5. "Crea spesa": categoria Trasporti, data e costo già messi.
6. Cambia vista (Elenco, Dettagli), ricarica: la vista resta.
7. Filtra per tipo e stato; un altro membro non vede "Elimina"
   sui tuoi trasporti, il proprietario sì.
8. Duplica il viaggio: la copia non ha trasporti.

## Tappa 3 - Prenotazioni

Commit:
- 8fe4652 docs: tappa 2 pubblicata.
- b631ff9 dati e regole (blocco reservations, test in
  rules-tests/sections) e filtro comune delle sezioni.
- 61180ab pagina Prenotazioni: tre viste, filtri, editor,
  spesa collegata (categoria Attività), eliminazione.

Prove da fare sul sito:
1. Prenotazioni è vuota; premi "+" e salva senza nome: compare
   il messaggio "Compila il campo «Nome»".
2. Crea un ingresso a un museo cercando il luogo su Google:
   la card mostra le foto e il pulsante Mappa.
3. Aggiungi data, ora, partecipanti e regole di cancellazione.
4. "Crea spesa": categoria Attività e titolo già messi.
5. Filtra per categoria e per stato; prova Prossimi/Passati.
6. Cambia vista e ricarica: la vista resta.
7. Un altro membro modifica ma non elimina la tua prenotazione.
8. Su telefono card ed editor si leggono senza tagli.

## Tappa 4 - Ristoranti

Commit:
- a89aab4 docs: tappa 3 pubblicata.
- be890e3 dati, regole (blocco restaurants: ognuno cambia solo il
  proprio voto) e servizio dei voti.
- 20a35f8 pagina Ristoranti: voti nella card, filtri per stato e
  prezzo, ordine, editor con contatti da Google, spesa collegata.

Prove da fare sul sito:
1. Aggiungi un ristorante cercandolo su Google: nome, telefono
   e sito si compilano; la card mostra le foto.
2. Scegli cucina, prezzo €€ e una prenotazione per 4 persone.
3. Vota SS; toccando di nuovo SS il voto si toglie.
4. Con un altro membro vota S: i conteggi si aggiornano e il
   tuo voto resta.
5. Ordina per voti, nome e prenotazione; filtra per prezzo.
6. "Contatta" e "Mappa" funzionano anche in Elenco e Dettagli.
7. "Crea spesa": categoria Cibo.
8. Su telefono card, voti ed editor si leggono senza tagli.

## Tappa 5 - Luoghi salvati

Commit:
- 26a4fa7 docs: tappa 4 pubblicata.
- f355e7a dati, regole (blocco savedPlaces) e lettura dei link di
  Google Maps (nome da /place/…, coordinate da @lat,lng o ?q=).
- 90e758e pagina Luoghi salvati.

Prove da fare sul sito:
1. Incolla un link di Google Maps di un luogo (dal browser):
   nome e posizione si compilano; salva.
2. Incolla un link corto (maps.app.goo.gl): il nome va scritto a
   mano, il link resta e si apre da "Google Maps".
3. Cerca un luogo su Google: la card mostra le foto.
4. La card dice "Aggiunto da" con il tuo nome.
5. Filtra per categoria; cambia vista e ricarica.
6. Il proprietario elimina un luogo di un altro membro; un
   membro non vede "Elimina" sui luoghi altrui.
7. Su telefono card ed editor si leggono senza tagli.

## Tappa 6 - Note

Commit:
- e3b29de docs: tappa 5 pubblicata.
- a6760e2 dati e regole (blocco notes: le private solo per
  l'autore, con test) e lettura con più richieste nel modulo comune.
- c882990 pagina Note: private, fissate, checklist, Info utili.

Prove da fare sul sito:
1. Crea una nota con "Usa il modello Info utili": è fissata
   in alto e ha Wi-Fi e numero di emergenza.
2. Crea una nota privata con una checklist di 3 voci.
3. Con un altro membro: la nota privata non si vede; la nota
   condivisa sì.
4. L'altro membro modifica una nota condivisa ma non può
   renderla privata (l'interruttore è spento).
5. Spunta una voce dalla card: il conteggio "1 di 3 fatte" cambia.
6. Filtra Condivise / Private; cambia vista e ricarica.
7. Il proprietario del viaggio elimina una nota condivisa di un
   altro; nessuno vede le note private altrui.
8. Su telefono card ed editor si leggono senza tagli.

## Tappa 7 - Shopping e valigia

Commit:
- e222ae3 docs: tappa 6 pubblicata.
- c1c7b12 dati e regole (blocchi shoppingItems e packingItems).
- cf9d283 pagina Shopping con schede Acquisti e Valigia.

Prove da fare sul sito:
1. Acquisti: aggiungi un regalo per un altro viaggiatore con
   budget stimato e negozio.
2. Dopo l'acquisto scrivi il prezzo reale e spunta "Comprato"
   dalla card.
3. "Crea spesa": categoria Shopping e importo dal prezzo reale.
4. Filtra Da comprare / Comprati e per persona.
5. Valigia: aggiungi voci per te, per un altro e per tutti, con
   quantità; spuntale dalla card.
6. Filtra la valigia per persona; cambia vista e ricarica.
7. Su telefono le due schede e gli editor si leggono senza tagli.

## Tappa 8 - Ricordi

Commit:
- c4ff93e docs: tappa 7 pubblicata.
- 46df481 dati, regole (blocco memories) e pagina Ricordi con
  diario (valutazione e momento del giorno, già dal prompt v2) e
  album esterni.

Prove da fare sul sito:
1. Scrivi la pagina di diario di oggi con 4 stelle e il momento
   del giorno.
2. Aggiungi un album: senza link non si salva; con il link di
   Google Foto sì, e "Apri l'album" lo apre.
3. La card dice "Scritto da" con il tuo nome.
4. Filtra Diario / Album, Prossimi / Passati; cambia vista e
   ricarica.
5. Un altro membro modifica il tuo diario ma non lo elimina.
6. Su telefono card ed editor si leggono senza tagli.

## Tappa 9 - Esportazione spese

Commit:
- e882527 pulsante "Esporta spese" nella pagina spese (unica riga
  aggiunta alla pagina approvata): CSV per Excel (separatore ";",
  virgola decimale in italiano, UTF-8 con BOM) e pagina da stampare
  o salvare come PDF dal browser. Solo lettura, una volta sola.
- Scelta: nessun pacchetto PDF aggiunto (quello diffuso non stampa
  i caratteri non latini); il PDF lo crea il browser con "Salva come
  PDF". File web/amaterasu_files.js caricato da web/index.html.
- Contenuto: spese condivise visibili a te e tue personali (data,
  titolo, categoria, stato, totale, chi ha pagato, quote, note),
  rimborsi, totali per valuta (annullate escluse), quota e pagato
  per persona.

Prove da fare sul sito:
1. Spese > icona Condividi > "CSV per Excel": si scarica spese.csv;
   aprilo con Excel: colonne separate, importi con la virgola.
2. Le spese annullate compaiono come "Annullata" ma non nei totali.
3. "PDF": si apre una scheda con le tabelle e la finestra di stampa;
   scegli "Salva come PDF".
4. Se il browser blocca i pop-up compare il messaggio: consenti i
   pop-up e riprova.
5. In inglese le colonne e gli stati sono in inglese.

## Tappa 10 - Analisi (solo lettura, nessuna modifica)

### a) Archivio Google Drive del viaggio
- Di chi è: del viaggiatore che crea il viaggio. Alla creazione
  sceglie una cartella del SUO Drive e l'app crea dentro una
  sottocartella col nome del viaggio
  (GoogleDriveArchiveService.createTripArchive).
- Permessi: l'app chiede solo lo scope drive.file (vede solo i file
  e le cartelle che crea lei). Non condivide la cartella con gli
  altri membri: nel codice non c'è nessuna chiamata ai permessi di
  Drive. Gli altri membri oggi NON possono aprire né scriverci.
- Metadati: nel documento del viaggio, campo cloudArchive
  (provider, folderId, folderName, folderUrl, accountEmail), scritto
  alla creazione e permesso da firestore.rules; nessun file su
  Firebase Storage.
- Limiti per le ricevute: (1) solo il creatore ha il token Drive, gli
  altri dovrebbero passare dal suo account o la cartella andrebbe
  condivisa (scrittura a ogni membro: serve la sua email Google e lo
  scope drive.file non basta per vedere file creati da altri);
  (2) ogni accesso chiede l'autorizzazione Google nel browser;
  (3) le spese private non devono finire in una cartella condivisa.
- Proposta: ricevute come LINK (già possibile col campo link) e, per
  chi vuole, "Allega" che carica nella PROPRIA cartella Drive di chi
  allega (non quella del viaggio), salvando nella spesa solo il link;
  per le spese private la cartella resta personale. Da decidere con
  BUDGET-2 (punto K del prompt v2).

### b) Budget previsto per categoria
- Esiste solo un budget personale complessivo e privato
  (budgetPrivateOwners/{uid}/settings/personalBudget: amountMinor e
  currency), con il calcolo dello speso
  (personal_budget_spending_calculator.dart). Non esiste un budget
  per categoria né di gruppo.
- Manca: importi per categoria (mappa categoria -> importo) nello
  stesso documento privato o in uno di gruppo, regole Firestore per i
  nuovi campi, confronto previsto/speso per categoria nella
  dashboard e avviso al superamento. Tocca regole e schermate del
  budget (approvato): si fa solo dopo l'ok, nell'analisi BUDGET-2.

# Prompt v2 (verso la 2.0.0)

Ordine: Passo 0, Passo 1, U1, 1b, sezioni, Crea spesa dalle sezioni,
extra A-H, nuove tappe 1-4, analisi Budget (K), documento Mappa e
Itinerario (L); poi stop per l'ok (COERENZA, HOME-VIAGGIO, BUDGET-2,
Mappa/Itinerario).

| Tappa v2 | Stato | Branch | Versione |
|---|---|---|---|
| Passo 0 - regole fisse in CLAUDE.md | fatta | docs/v2-regole-analisi | - |
| Passo 1 - INVENTARIO-UI, COSTI, API-ESTERNE, DIRETTIVE-UI | fatta | docs/v2-regole-analisi | - |
| U1 - componenti condivisi delle direttive | fatta (pubblicazione: vedi 1b) | feature/ui-componenti | 1.24.0+28 |
| 1b - correzioni di stile (filtri, valuta, nomi, allergeni, checklist, foto) | da fare | - | - |
| Sezioni - aggiunte v2 | da fare | - | - |
| Crea spesa dalle sezioni | da fare | - | - |
| Extra A-H | da fare | - | - |
| Nuove tappe 1-4 | da fare | - | - |
| K - BUDGET-2 (solo analisi) | da fare | - | - |
| L - MAPPA-ITINERARIO (solo documento) | da fare | - | - |

## U1 - Componenti condivisi delle direttive
Valutazione (regola 1): (a) esistevano AmaterasuPrimaryButton (56, tutta
larghezza), AlertDialog sparsi, i blocchi aperti dell'editor sezioni;
(b) nuovi componenti in lib/core/widgets riusati in modo identico, il
pulsante da 56 resta per le schermate di accesso; (c) toccano solo il
modulo sections (non i moduli approvati); test nuovi e test delle
sezioni aggiornati (doppia conferma, matita in alto).

Commit:
- f1da8d5 AmaterasuButton (principale, secondario, terziario,
  distruttivo), AmaterasuEditButton (matita; "Modifica" su schermo
  largo), showAmaterasuSheet (pannello dal basso sul telefono,
  finestra al centro su schermo largo), confirmAmaterasuAction (doppia
  conferma per le azioni distruttive, nello stesso pannello),
  AmaterasuFoldSection (sezione a tendina con riepilogo). Le sezioni
  nuove li usano: blocchi a tendina, Salva/Annulla, matita in alto
  nella card, eliminazione con doppia conferma.
- Da completare nella tappa delle sezioni: riepiloghi delle sezioni
  chiuse e "solo la sezione essenziale aperta in creazione" editor per
  editor (oggi i blocchi partono aperti); su errore restano aperti.

Prove da fare sul sito:
1. In una sezione nuova (es. Trasporti) tocca il titolo di un blocco
   dell'editor: si chiude e si riapre.
2. Su schermo largo la card mostra "Modifica" con la matita in alto; su
   telefono solo la matita.
3. Elimina un elemento: pannello rosso, poi "Sei sicuro?" e "Sì,
   conferma"; su telefono il pannello sale dal basso.
4. Salva e Annulla dell'editor hanno lo stesso aspetto in tutte le
   sezioni nuove.

