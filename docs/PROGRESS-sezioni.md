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
| U1 - componenti condivisi delle direttive | fatta, pubblicata 1.24.0 il 24/11/2026 | feature/ui-componenti | 1.24.0+28 |
| 1b parte 1 - filtri, valuta, nomi, allergeni, luoghi, foto | fatta, pubblicata 1.25.0 il 24/11/2026 | feature/stile-1b | 1.25.0+29 |
| 1b parte 2 - sezione Checklist | fatta, pubblicata 1.26.0 il 25/11/2026 | feature/checklist | 1.26.0+30 |
| Sezioni v2 - Trasporti | fatta, pubblicata 1.27.0 il 25/11/2026 | feature/trasporti-v2 | 1.27.0+31 |
| Sezioni v2 - Prenotazioni | fatta, pubblicata 1.28.0 il 25/11/2026 | feature/prenotazioni-v2 | 1.28.0+32 |
| Sezioni v2 - Ristoranti | fatta, pubblicata 1.29.0 il 25/11/2026 | feature/ristoranti-v2 | 1.29.0+33 |
| Sezioni v2 - Luoghi salvati | fatta, pubblicata 1.30.0 il 25/11/2026 | feature/luoghi-v2 | 1.30.0+34 |
| Sezioni v2 - Alloggi (aggiunte facoltative) | fatta, pubblicata 1.31.0 il 25/11/2026 | feature/alloggi-v2 | 1.31.0+35 |
| Sezioni v2 - Note | fatta, pubblicata 1.32.0 il 25/11/2026 | feature/note-v2 | 1.32.0+36 |
| Sezioni v2 - Shopping | fatta, pubblicata 1.33.0 il 25/11/2026 | feature/shopping-v2 | 1.33.0+37 |
| Sezioni v2 - Link utili ovunque (senza Spese) | fatta, pubblicata 1.34.0 il 25/11/2026 | feature/link-utili | 1.34.0+38 |
| Crea spesa dalle sezioni (+ link delle spese) | fatta, pubblicata 1.35.0 il 25/11/2026 | feature/crea-spesa | 1.35.0+39 |
| Chiusure: link nel testo delle note, test valuta trasporti, test selezione multipla | fatta, pubblicata 1.35.1 il 25/11/2026 | fix/chiusure-v2 | 1.35.1+40 |
| Extra A - Novità e versioni | fatta, pubblicata 1.36.0 il 25/11/2026 | feature/novita | 1.36.0+41 |
| Extra B - Sito installabile (PWA) | fatta, pubblicata 1.37.0 il 25/11/2026 | feature/pwa | 1.37.0+42 |
| Extra C - Fuso orario per città (migrazione non necessaria) | fatta, pubblicata 1.38.0 il 25/11/2026 | feature/fuso-citta | 1.38.0+43 |
| Extra D - Categorie personalizzate | fatta, pubblicata 1.39.0 il 25/11/2026 | feature/categorie | 1.39.0+44 |
| Extra D - Filtro per categoria personalizzata | fatta, pubblicata 1.40.0 il 25/11/2026 | feature/filtro-categorie | 1.40.0+45 |
| Extra E - Aspetto: piano | approvato il 25/11/2026 | - | - |
| Extra E1 - Preferenze Aspetto (modello e salvataggio) | fatta, pubblicata 1.41.0 il 25/11/2026 | feature/aspetto-e1 | 1.41.0+46 |
| Extra E2 - Pagina Impostazioni > Aspetto | fatta, pubblicata 1.42.0 il 25/11/2026 | feature/aspetto-e2 | 1.42.0+47 |
| Extra E3 - Dimensione del testo in tutta l'app | fatta, pubblicata 1.43.0 il 25/11/2026 | feature/aspetto-e3 | 1.43.0+48 |
| Extra E4 - Formato di data e ora nelle sezioni nuove | fatta, pubblicata 1.44.0 il 25/11/2026 | feature/aspetto-e4 | 1.44.0+49 |
| Extra E5 - Unità km/miglia | nulla da pubblicare: la scelta è salvata (E1), la useranno Mappa, Itinerario e Converti | - | - |
| Extra E6 - Valuta per le nuove voci | fatta, pubblicata 1.45.0 il 25/11/2026 | feature/aspetto-e6 | 1.45.0+50 |
| Extra E7 - Valuta di visualizzazione | fatta, pubblicata 1.46.0 il 25/11/2026 | feature/aspetto-e7 | 1.46.0+51 |
| Extra E8 - TEMA-CHIARO.md | fatta (solo documento, nessun rilascio) | docs/tema-chiaro | - |
| Extra F - Assistenza e privacy | fatta, pubblicata 1.47.0 il 25/11/2026 | feature/assistenza | 1.47.0+52 |
| Extra G - Caricamento con il sole | fatta, pubblicata 1.48.0 il 25/11/2026 | feature/caricamento | 1.48.0+53 |
| Extra H - Verifica finale | fatta (vedi sotto) | docs/verifica-finale | - |
| Nuova tappa 1a - Converti | fatta (pubblicazione: vedi tappa seguente) | feature/converti | 1.49.0+54 |
| Nuova tappa 1b - Meteo | fatta | feature/meteo | 1.50.0+56 |
| Nuova tappa 1c - Info paese | fatta | feature/info-paese | 1.51.0+57 |
| Nuova tappa 2a - Cerca nelle sezioni | fatta | feature/cerca-globale | 1.52.0+58 |
| Nuova tappa 2b - Risalto del risultato | fatta | feature/cerca-evidenzia | 1.53.0+59 |
| Nuova tappa 2c - Cerca in spese e bucket list | fatta | feature/cerca-spese-bucket | 1.54.0+60 |
| Nuova tappa 3a - Calendario .ics | fatta | feature/calendario-ics | 1.55.0+61 |
| Nuova tappa 3b - Statistiche | fatta | feature/budget-totali-condivisi | 1.56.0+62 |
| Nuova tappa 3c - PDF del viaggio | fatta | feature/pdf-viaggio | 1.57.0+63 |
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

## 1b - Correzioni di stile (parte 1: punti 1, 2, 3, 4, 5, 7)
Valutazioni (regola 1):
- Nomi: (a) il budget usa già lo username (BudgetApi.travelers); (b)
  funzione condivisa tripMemberShownName; (c) cambia il provider dei nomi
  di alloggi e sezioni; test del nome. Le impostazioni del viaggio
  (approvate) mostrano ancora il nome completo: in COERENZA.
- Filtri: (a) componente degli alloggi; (b) estratto in
  lib/core/widgets/filters con chiavi e testi identici; (c) alloggi (77
  test invariati) e tutte le sezioni nuove; test aggiornati.
- Valuta: (a) pulsante e pannello del budget, copiati in 3 file; (b)
  budget_currency_choice.dart usato dal dialogo spese (272 test del
  budget invariati), da alloggi e sezioni; toolbar e budget personale
  hanno ancora la loro copia (TODO(audit) C7); (c) nessun calcolo
  toccato.
- Allergeni/diete: nuovi campi dei ristoranti; regole del blocco
  restaurants ampliate (solo campi nuovi), test regole e widget.
- Luoghi salvati: contatti (telefono, sito) da Google; regole del blocco
  savedPlaces ampliate, test.
- Foto: carosello condiviso: nella card solo la prima foto, conteggio e
  "Google Maps"; visore al tocco con fino a 5 foto e autori; test.

Commit: f33b7cd nomi, da3cbdb filtri, fb828ce valuta, 5cbb8ec allergeni
e diete, 0e59d21 contatti dei luoghi salvati, 00b524f foto.

Impatto su firestore.rules: solo campi facoltativi nuovi nei blocchi
restaurants (allergens, allergenNotes, diets) e savedPlaces (phone,
website); permessi invariati.

Prove da fare sul sito:
1. In Trasporti un solo pulsante "Filtri": apre il pannello, il numero
   dei filtri attivi compare sul pulsante, "Azzera filtri" li toglie.
2. Negli alloggi i filtri funzionano come prima.
3. Costo previsto (alloggi, trasporti, ristoranti, shopping): il
   pulsante "Valuta: EUR" apre lo stesso pannello di ricerca del budget.
4. Nelle sezioni nuove passeggeri, ospiti e autori mostrano lo username.
5. Ristorante: spunta Glutine e Arachidi e "Vegano": la card mostra
   "Da segnalare: …" e l'etichetta; filtro Allergeni sì/no.
6. Luogo salvato cercato su Google: telefono e sito compilati;
   "Contatta" funziona.
7. Card con foto: si vede una sola foto con "Google Maps" e il numero
   di foto; toccandola si apre il visore con frecce e autori.

## 1b parte 2 - Sezione Checklist
Valutazione (regola 1): (a) esistevano la lista valigia di Shopping e la
checklist dentro le Note; (b) nuova sezione Checklist con il modulo comune
delle sezioni e i componenti U1 (sezioni a tendina, pannello, doppia
conferma), la valigia di Shopping si importa e la scheda Valigia sparisce;
(c) nuovo blocco checklists nelle regole (liste personali solo per
l'autore, al massimo 300 voci), duplicateTrip la esclude (functions da
ripubblicare), test di regole e widget.

Commit: 1cfcdb0 dati, regole e modelli pronti; de974c7 pagine Checklist,
import della valigia, Shopping senza scheda Valigia.

Impatto su firestore.rules: nuovo blocco checklists (membri leggono le
liste condivise e le proprie personali; eliminano autore o proprietario,
mai le personali altrui). Nessun blocco esistente cambiato.

Prove da fare sul sito:
1. Altro > Checklist > "+": scegli Valigia e salva: 3 categorie, 17 voci.
2. Spunta voci dalla lista: barra della categoria e "x su y" cambiano;
   un altro membro vede le spunte.
3. Scrivi un numero nella casella della quantità e premi Invio.
4. Aggiungi una voce in fondo a una categoria e una nuova categoria.
5. Tocca una voce: cambia assegnatario (username) o eliminala (doppia
   conferma).
6. Filtri: Da fare / Fatte e per persona; tieni premuta una voce e
   trascinala per riordinare (senza filtri attivi).
7. Menu: Azzera le spunte, Duplica la lista, Stampa, Esporta CSV.
8. Lista personale: un altro membro non la vede. Se avevi voci nella
   vecchia Valigia di Shopping compare "Importa la lista valigia".

## Sezioni v2 - Trasporti
Valutazione (regola 1): (a) esistevano posti come testo libero, avvisi di
coincidenza e orari con fuso; (b) nuovi dettagli raccolti in un campo
"extras" del trasporto, scali calcolati dagli orari già salvati (nessuna
API), stato del volo come semplice link; (c) tocca solo il blocco
transports delle regole e le funzioni section*; test di regole e widget.

Commit: 1f2de63.

Nota tecnica sulle regole: Firestore conta al massimo 1000 operazioni per
ogni controllo. Il documento di un trasporto con tutti i campi lo
superava. Soluzione: funzioni section* più corte ("il campo non c'è,
oppure è valido"), controlli leggeri (autore, data del server) per primi,
testi del blocco transports scritti in linea, nuovi campi raggruppati in
"extras". Conseguenza: nei blocchi nuovi un campo presente ma vuoto (null)
viene rifiutato; l'app non li scrive mai.

Prove da fare sul sito:
1. Due voli con lo stesso codice di prenotazione (Roma→Doha, Doha→Tokyo):
   sulla seconda card compare "Scalo di … a Doha".
2. Nel blocco "Posti, check-in e noleggio" scrivi Lettera e Posto di un
   passeggero: la card mostra "Posti: username C · 23A".
3. Un volo fra più di 24 ore mostra "Check-in apre tra …"; con il link del
   check-in compare il pulsante.
4. "Arriva in aeroporto entro le …" è 2 ore prima della partenza (o i
   minuti che scegli).
5. "Stato del volo" apre FlightAware con il numero del volo.
6. Un noleggio auto mostra carburante e franchigia.

## Sezioni v2 - Prenotazioni
Valutazione (regola 1): (a) esistevano stato (da prenotare / prenotato /
annullato), codice e partecipanti; (b) nuovi campi aggiunti al modello
esistente, scadenza mostrata con l'etichetta comune TripSectionChip, QR
generato nel browser con il pacchetto qr_flutter (nessuna API, nessun
file); (c) tocca solo il blocco reservations delle regole; test di regole,
modello, card, biglietto ed editor.

Commit: 33688ef.

Prove da fare sul sito:
1. Prenotazione "da prenotare" con "Da prenotare entro il" fra 2 giorni:
   l'etichetta sulla card è rossa; fra un mese è dorata.
2. Passando a "prenotato" la scadenza non compare più.
3. Intestatario e numero di biglietti compaiono nella card.
4. Con il codice del biglietto compare "Mostra biglietto": si apre a
   schermo intero con il QR e il codice sotto; "Chiudi" torna all'elenco.
5. Il QR si legge con la fotocamera di un telefono.

## Sezioni v2 - Ristoranti
Valutazione (regola 1): (a) esistevano dieta e allergeni, fascia di
prezzo €-€€€€ scritta a mano, stato "provato" e contatti Google nel
modulo Luogo; (b) orari e prezzo aggiunti alla stessa richiesta Google
dei contatti nel modulo condiviso lib/core/places (nessun costo in più),
cambio con il servizio Frankfurter già usato dal budget (solo lettura),
stelle spostate in un modulo comune (tripSectionStars, usato anche dai
Ricordi); (c) tocca il blocco restaurants delle regole (triedRating,
triedNote); test di regole, orari, pannello ed editor.

Commit: a568221.

Dieta: già fatta nella 1.25.0. Gli orari non si salvano: si leggono solo
toccando "Orari e prezzi".

Prove da fare sul sito:
1. Ristorante con luogo Google: nella card compare "Orari e prezzi";
   toccandolo si vedono gli orari della settimana.
2. Con una prenotazione in un giorno di chiusura compare l'avviso rosso
   "risulta chiuso" (solo informativo).
3. Se Google ha la fascia di prezzo, compare "Prezzo indicativo…" e, se
   la valuta è diversa da quella del viaggio, "Circa … al cambio di oggi".
4. Stato "provato": nell'editor compaiono stelle e "Com'è stato"; la
   card mostra le stelle e la nota.
5. Nei Ricordi le stelle si vedono come prima.

## Sezioni v2 - Luoghi salvati
Valutazione (regola 1): (a) esistevano luogo Google, contatti, categoria
e il pannello "Orari e prezzi" dei ristoranti; (b) il pannello e il suo
pulsante sono stati spostati nel modulo comune delle sezioni
(TripSectionHoursButton, stesso comportamento nei ristoranti) e riusati
identici; il prezzo d'ingresso usa i campi e il selettore di valuta del
costo comune; l'elenco comune ha ora i titoli di gruppo (groupOf); (c)
tocca il blocco savedPlaces delle regole; test di regole, dati, ordine,
gruppi, filtro ed editor.

Commit: ead63cc, 885aa4e.

Categorie personalizzate: rinviate al componente D (tappe extra), così
si fanno una volta sola per tutte le sezioni.

Prove da fare sul sito:
1. Nell'editor, blocco "Visita": priorità SS/S/A/B, Visitato, giorno,
   zona, tempo, prezzo d'ingresso con valuta e link dei biglietti.
2. L'elenco parte ordinato per priorità (SS in alto).
3. Filtri > Ordina "Per zona" e "Per giorno": compaiono i titoli dei
   gruppi; i luoghi senza zona o giorno sono in fondo.
4. Filtro "Da visitare" nasconde i visitati; i visitati appaiono attenuati.
5. "Orari e prezzi" sui luoghi Google; con il giorno previsto in un
   giorno di chiusura compare l'avviso.

## Sezioni v2 - Alloggi (solo aggiunte facoltative)
Valutazione (regola 1): (a) esistevano servizi, "come arrivare", costo
previsto e il selettore di valuta comune; (b) le aggiunte sono raccolte
in un campo "extras" (come nei trasporti) con una sezione nuova
dell'editor e righe nuove nella card che compaiono solo se compilate; il
resto del modulo approvato non cambia; (c) tocca il blocco stays delle
regole (chiave extras e funzione validStayExtras); test di regole, dati,
card ed editor.

Commit: 0a094bb.

Impatto sulle regole: un alloggio può avere in più il campo "extras"
(codice porta, Wi-Fi, istruzioni, orario di arrivo tardivo, contatto
reception, tassa di soggiorno con valuta e persone); tutto il resto è
controllato come prima. Con tutti i campi insieme si superava il limite di
1000 operazioni di Firestore: ogni testo di "extras" ha un solo controllo
(che verifica anche che sia un testo).

Prove da fare sul sito:
1. Nell'editor di un alloggio c'è la sezione "Arrivo, accesso e tassa".
2. Codice porta e Wi-Fi compaiono nella card solo se compilati.
3. Arrivo tardivo e reception: "Arrivo alle 23:30 · Reception: …".
4. Tassa a persona per notte: la card mostra il totale (notti × persone;
   se "persone" è vuoto si usano gli ospiti).
5. Un alloggio già salvato senza queste aggiunte appare come prima.

## Sezioni v2 - Note
Valutazione (regola 1): (a) esistevano note private, checklist e il
modello "Info utili"; (b) la formattazione di base è un modulo comune
delle sezioni (tripSectionRichText, attivato con TripSectionLine
formatted) così altre sezioni potranno riusarla; gli elementi da
collegare si leggono una volta sola con i negozi esistenti, solo
aprendo "Collega"; (c) tocca il blocco notes delle regole (linkSection,
linkId, linkName); test di regole, testo formattato, card ed editor.

Commit: dcfdcb9.

"Link utili" nelle note: arriva con la tappa "Link ovunque" (campo comune
per tutte le sezioni).

Prove da fare sul sito:
1. Nota nuova: tre modelli (Info utili, Frasi utili, Contatti).
2. Barra sopra il testo: Titolo, Elenco, Grassetto; nella card il titolo è
   in grassetto, le righe "- " diventano punti elenco.
3. "Collegata a" > Collega: compaiono alloggi, trasporti, prenotazioni,
   ristoranti e luoghi del viaggio; la card mostra "Collegata a …".
4. Il collegamento si toglie con l'icona accanto.

## Sezioni v2 - Shopping
Valutazione (regola 1): (a) esistevano "per chi" (un viaggiatore),
comprato e la spunta dalla card; le priorità SS/S/A/B esistevano nei
luoghi salvati; (b) la priorità è ora un modulo comune
(TripSectionPriority, usato da luoghi salvati e shopping); l'editor usa
uno stato a parte (trip_shopping_draft.dart) come le prenotazioni; (c)
tocca il blocco shoppingItems delle regole (forText, priority,
boughtByUid); test di regole, card ed editor.

Commit: df35f7f.

Prove da fare sul sito:
1. Editor: "Per chi (scritto da te)" accetta anche chi non viaggia
   (es. Nonna), insieme al viaggiatore scelto.
2. Priorità SS/S/A/B: la lista mette in alto le SS.
3. Spuntando "comprato" dalla card compare "Comprato da <username>".
4. Togliendo la spunta "Comprato da" sparisce.

## Sezioni v2 - Link utili ovunque
Valutazione (regola 1): (a) la bucket list ha il suo campo "Link utili"
(elenco di indirizzi) e le card delle sezioni mostravano già i link come
chip; (b) creato il campo comune AmaterasuLinksField in lib/core/links con
lo stesso aspetto e comportamento di quello della bucket list (che resta
com'è, approvata), il blocco TripSectionLinksBlock e TripSectionLinks
(campo usefulLinks, al massimo 10); (c) tocca le regole delle sezioni
nuove (funzione sectionLinks e chiave usefulLinks); test di regole, dati,
editor e card.

Commit: 4715b67.

Dove: Trasporti, Prenotazioni, Ristoranti, Luoghi salvati, Note,
Shopping, Ricordi (blocco "Link utili" in fondo all'editor, chip con il
nome del sito nella card) e voci della Checklist (fino a 3 link nella
scheda della voce, chip sotto la voce).

Spese: NON fatto. La funzione del server che crea e modifica le spese
(Cloud Function del modulo soldi, approvato) non ha un campo link:
servirebbe cambiarla. Come chiesto dal prompt mi fermo qui e aspetto
l'ok.

Impatto sulle regole: (1) nelle sezioni nuove è ammesso il campo
usefulLinks (fino a 10 indirizzi http/https senza spazi, controllati
insieme con un solo confronto; il limite di 2048 caratteri per link resta
nell'app). (2) Le funzioni comuni section* (luogo, giorno, ora, fuso) e i
testi brevi dei trasporti ora usano un solo controllo per campo, con lo
stesso significato: senza questo, un trasporto con tutti i campi più
costo e spesa collegata superava già il limite di 1000 operazioni di
Firestore (problema presente dalla 1.27.0, ora risolto e coperto da un
test). Le regole degli alloggi, del budget e della bucket list non
cambiano.

Prove da fare sul sito:
1. In ogni editor delle sezioni elencate c'è "Link utili" in fondo:
   aggiungi due link, salva; nella card compaiono come chip col sito.
2. Un link senza http:// o https:// non si salva e compare l'errore.
3. Nella Checklist apri una voce, aggiungi un link: compare sotto la voce.
4. Un trasporto con molti campi compilati, costo e spesa collegata si
   salva senza errori.

## Crea spesa dalle sezioni
Valutazione (regola 1): (a) le sezioni aprivano già il dialogo spese del
budget con valori iniziali; nessun secondo dialogo; (b) le correzioni sono
fatte nel dialogo del budget (nuovo file part budget_create_dialog_kind.dart)
e valgono ovunque; i nomi erano già gli username (listTripMembers); (c)
tocca la Cloud Function createBudgetExpense solo per due campi facoltativi
validati (source e link, modulo budget-expense-source.ts con test), nessun
cambiamento ai calcoli; test di regressione del budget prima e dopo (270
test Flutter + 3 suite con emulatori, tutti verdi).

Commit: b3e28a2.

Cosa cambia nel dialogo spese:
1. Tipo: "Con tutti", "Con alcune persone", "Anticipata per altri" (chi
   crea non partecipa) e "Personale" (non dalle sezioni, come prima).
2. "Totale da dividere / Per persona": per persona il totale è prezzo ×
   partecipanti, calcolato prima dell'invio e mostrato nel riepilogo.
3. Pulsante "Tutti" sopra i viaggiatori.
4. Link facoltativo (validato http/https).
5. Dalle sezioni e dagli alloggi la spesa ricorda la sezione di origine;
   nel dettaglio della spesa il riquadro "Origine e link" ha "Vai al
   trasporto / all'alloggio / …" e il link.

Selezione di più persone: con i test automatici il dialogo seleziona
correttamente più viaggiatori (anche a larghezza telefono e dalle
sezioni). Non ho trovato la causa del problema segnalato: servono i passi
esatti (da quale schermata, con quanti viaggiatori, telefono o computer).

Prove da fare sul sito:
1. Da un trasporto: "Crea spesa" > "Con tutti" > tutti selezionati.
2. "Per persona" 12 € con 3 persone: il riepilogo mostra 36 €.
3. "Anticipata per altri": tu non sei tra i partecipanti.
4. Nel dettaglio della spesa creata: "Origine e link" > "Vai al trasporto".
5. Una spesa creata dalla pagina spese senza link: nessun riquadro nuovo.
6. Prova a selezionare due persone e dimmi se il problema c'è ancora.

## Chiusure dopo la 1.35.0
1. Note: gli indirizzi web scritti nel testo (http/https) diventano link
   da toccare e si aprono con AmaterasuLinkOpener (lib/core/links), come
   i Link utili. Il punto o la virgola finale restano fuori dal link.
   Modulo comune tripSectionRichText (parametro onLink).
2. Test della valuta dei trasporti rimesso: budgetCurrencyChoices ha ora
   un punto di sostituzione solo per i test (budgetCurrencyFetch); l'app
   usa sempre Google come prima. Il test sceglie JPY da una lista finta.
3. Selezione di più persone nel dialogo spese, percorsi provati con test:
   - dialogo aperto da solo, finestra larga, tocco sul nome (3 persone);
   - dialogo "solo condivisa" a larghezza telefono (390), tocco sulla
     casella (3 persone);
   - "Con tutti", togli una persona, pulsante "Tutti";
   - dalla card di un trasporto ("Crea spesa"), tocco sul secondo
     viaggiatore: selezionati in due.
   Non provati (servono il sito vero o i tuoi passi): l'elenco dei membri
   letto dal server (listTripMembers) con viaggiatori reali, il pannello
   delle revisioni di una spesa già creata, il telefono vero (tocco).

Prove da fare sul sito:
1. Nota con "Sito: https://…" nel testo: il link si apre in una scheda.
2. "Crea spesa" da un trasporto con due persone: selezionale entrambe.

## Extra A - Novità e versioni
Valutazione (regola 1): (a) esisteva solo la riga "Versione" nelle
Impostazioni > Informazioni app (senza azione) e nessun file delle
novità; (b) nuovo modulo comune lib/core/changelog (lettura del file,
pannello "Cosa c'è di nuovo", elenco versioni) con il pannello comune
AmaterasuSheet; nelle Impostazioni (approvate) cambia solo il tocco sulla
versione, come chiesto dal prompt; (c) tocca router (avvolge la shell
globale), firebase.json (cache), pubspec (asset); test del file, "una
volta sola", pannello ed elenco.

1. All'apertura, se la versione installata è diversa dall'ultima vista,
   compare UNA volta "Novità della versione X" (solo quella versione, in
   italiano o inglese). Alla prima installazione non compare nulla.
2. Impostazioni > Informazioni app > Versione: tutte le versioni a
   tendina, la più recente aperta in alto, con data e novità.
3. File unico assets/changelog/changelog.json (it/en), ricostruito dai
   tag dalla 1.10.0. Regola di rilascio: bash tool/check_changelog.sh
   X.Y.Z è il primo passo del rilascio (si ferma se manca la voce) e un
   test controlla la versione di pubspec. Scritto nel README.
4. Aggiornamento automatico: il sito non aveva regole di cache, quindi il
   browser poteva tenere la versione vecchia fino a un'ora. Ora tutte le
   pagine e i file hanno "Cache-Control: no-cache" (firebase.json): alla
   riapertura si carica la nuova versione, senza avvisi. La verifica
   dopo la pubblicazione controlla l'intestazione sul sito vero.

Prove da fare sul sito:
1. Apri il sito dopo questa pubblicazione: compare "Novità della versione
   1.36.0" una sola volta (riaprendo non ricompare).
2. Impostazioni > Informazioni app > tocca "Versione": elenco a tendina.
3. Lascia una scheda aperta, alla prossima pubblicazione ricaricala: vedi
   la versione nuova senza svuotare la cache.

## Extra B - Sito installabile come app (PWA)
Valutazione (regola 1): (a) il manifest era già quasi pronto (nome,
standalone, icone 192/512 anche maskable, tutte esistenti) ma nessun
service worker veniva registrato: il caricatore di Flutter lo registra solo
se richiesto (ed è deprecato); (b) aggiunto un service worker minimo
(web/amaterasu_sw.js) senza cache né offline, registrato da index.html;
manifest con id, start_url e scope "/"; meta per iPhone; (c) tocca solo
web/; test sui file e verifica dopo la pubblicazione (service worker e
manifest standalone sul sito vero).

Perché l'icona apriva Chrome: senza un service worker registrato Android
creava un semplice collegamento al sito invece di installare l'app.

Prove da fare sul sito:
1. Android, Chrome: menu ⋮ > "Installa app" (o il banner); l'icona apre
   l'app a tutto schermo, senza barra degli indirizzi. Se c'era il vecchio
   collegamento, toglilo e installa di nuovo.
2. iPhone, Safari: Condividi > "Aggiungi alla schermata Home"; si apre a
   tutto schermo.
3. Computer, Chrome: icona "Installa" nella barra degli indirizzi.

## Extra C - Fuso orario per città
Valutazione (regola 1): (a) solo i trasporti avevano un fuso, scelto da
un elenco di scarti "UTC+1/+9"; prenotazioni e ristoranti solo l'ora
locale; (b) nuovo modulo comune lib/core/time_zones (ricerca della città
con Open-Meteo, ora e scarto con Intl del browser, pulsante con lo stesso
aspetto del selettore valuta) usato identico in trasporti, prenotazioni
e ristoranti; (c) tocca le regole dei tre blocchi (extras dei trasporti;
zone e zoneCity di prenotazioni e ristoranti), con test.

Come funziona: scegli la città, l'app salva il fuso (es. Europe/Rome) e la
città, e per i trasporti ricalcola l'offset del giorno del viaggio (ora
legale compresa). L'ora scritta non cambia mai. Senza città tutto resta
come prima: i trasporti vecchi mostrano ancora "(UTC+01:00)".

Migrazione dei dati: NON NECESSARIA (decisione del 25/11/2026). C'era un
solo trasporto di prova, che correggi a mano scegliendo la città. Lo
script che scrive non è stato scritto; resta solo il rapporto in sola
lettura qui sotto, come documentazione.
- Script di sola lettura functions/scripts/migrate-transport-zones-dry-run.cjs
  (piano in transport-zone-plan.cjs, con test). Aggiunge solo il nome del
  fuso equivalente all'offset salvato (es. +01:00 -> Etc/GMT-1), verificato
  data per data; non cambia offset, date né orari.
- Risultato sul progetto vero (25/11/2026): trasporti 1 letto, 1 da
  aggiornare, 0 saltati; prenotazioni 0; ristoranti 0 (non hanno fusi
  salvati: nulla da migrare).
- Esempio trasporto: prima departureOffset "+01:00" (13/08/2027 15:35),
  arrivalOffset "+09:00" (14/08/2027 17:35), extras senza fusi; dopo
  uguale + extras.departureZone "Etc/GMT-1", extras.arrivalZone "Etc/GMT-9".
  Visibile: identico ("15:35 (UTC+01:00)").
- Nota: il 13 agosto in Italia c'è l'ora legale (+02:00). Se il trasporto
  parte dall'Italia, l'offset salvato +01:00 era probabilmente da
  correggere: dopo il tuo ok basta riaprirlo e scegliere la città.

Prove da fare sul sito:
1. Trasporto: tocca "Fuso orario", scrivi "venezia", Cerca, scegli: il
   pulsante mostra "Venezia, ora locale …"; salvato, la card mostra
   "(Venezia, UTC+01:00)" o "+02:00" d'estate.
2. Prenotazione e ristorante: stesso selettore vicino all'ora; la card
   mostra la città tra parentesi.
3. Il trasporto già salvato appare come prima.

## Extra D - Categorie personalizzate
Valutazione (regola 1): (a) la bucket list ha la categoria "Altro": un
testo scritto a mano più i suggerimenti presi dalle categorie già usate
nel viaggio (raccolta bucketCategories, solo creazione); il codice sta
dentro il suo editor approvato; (b) stesso meccanismo come modulo comune
delle sezioni (TripSectionCategories, TripSectionCategoriesBlock, archivio
trips/{tripId}/sectionCategories con le stesse regole di bucketCategories),
con selezione multipla fino a 5; la bucket list NON è cambiata (79 test
uguali prima e dopo); (c) tocca le regole: nuova raccolta
sectionCategories e campo customCategories in 5 blocchi; test di regole
(anche un ristorante con tutti i campi, 10 link, fuso e 5 categorie
sotto il limite delle 1000 operazioni), modello, editor e card.

Dove: luoghi salvati, prenotazioni, ristoranti, note, shopping (blocco
"Categorie personalizzate" nell'editor, chip grigie nella card). Spese:
solo analisi nel documento K. Le categorie del viaggio si leggono una
volta all'apertura dell'editor. Il filtro per categoria personalizzata
nelle barre dei filtri non c'è ancora (si può aggiungere dopo l'ok).
duplicateTrip copia la raccolta sectionCategories come già fa con
bucketCategories (sono solo etichette, senza dati personali).

Prove da fare sul sito:
1. Luogo salvato: "Categorie personalizzate", scrivi "Romantico", +; salva.
2. In un'altra sezione, stesso viaggio: "Romantico" compare tra "Già
   usate nel viaggio".
3. Dopo 5 categorie il campo dice "Al massimo 5 categorie".
4. La card mostra le categorie come etichette grigie.

## Extra D - Filtro per categoria personalizzata
Valutazione (regola 1): (a) le barre dei filtri delle sezioni usano già il
componente comune (TripSectionFilter + tripSectionFilterGroups +
TripSectionToolbar); (b) la categoria personalizzata è un campo in più del
filtro comune (custom) e un gruppo in più dei gruppi comuni, così "Azzera"
e il conteggio dei filtri attivi funzionano da soli; il gruppo compare solo
se almeno un elemento ha una categoria; (c) tocca le 5 pagine (luoghi,
prenotazioni, ristoranti, note, shopping) solo per passare le categorie;
test del filtro e di due pagine.

Prove da fare sul sito:
1. Con almeno un luogo con la categoria "Romantico": Filtri > "Categoria
   personalizzata" > Romantico: restano solo quei luoghi.
2. "Azzera" toglie anche questo filtro.
3. In una sezione senza categorie il gruppo non compare.

## Extra E - Aspetto: valutazione e piano (IN ATTESA DI OK)
Nessun codice scritto. Tocca due moduli approvati (impostazioni e budget):
si parte solo dopo l'ok su questo piano. Nessun cambio ai calcoli.

Valutazione (regola 1):
(a) Esiste già: impostazioni globali a card (AmaterasuSettingsCard) con
    Lingua salvata nel dispositivo (languageProvider); profilo utente in
    viaggiatori/{uid} con campi fissi (username, nome, bio, foto...).
    Valuta di visualizzazione solo nella pagina spese: selettore
    temporaneo salvato nel dispositivo per viaggio; BudgetDisplayAmount
    converte con BudgetFxService (Frankfurter) ma ci sono più istanze del
    servizio (cache non condivisa) e mostra "Originale: X" anche quando la
    valuta è la stessa. Importi fuori dal budget: 5 punti (alloggi,
    shopping, TripSectionLabels per le sezioni), solo valuta originale.
    Date: 26 punti con i formati di Material (lingua dell'app). Distanze:
    nessuna oggi (arriveranno con Mappa/Itinerario e Converti).
(b) Conviene: un solo modello "Aspetto" con un solo provider; un modulo
    comune di conversione per la visualizzazione (stessa istanza e cache
    di BudgetFxService, un tasso per coppia di valute per sessione, mai
    per card) usato identico da budget, alloggi e sezioni; il selettore
    valuta resta BudgetCurrencyButton.
(c) Tocca: impostazioni (nuova card "Aspetto", il resto invariato),
    regole di viaggiatori/{uid} (un campo facoltativo "appearance"),
    MaterialApp (dimensione del testo), budget solo nella visualizzazione
    (valore iniziale del selettore e riga "Originale"), alloggi e sezioni
    nella visualizzazione degli importi. Test: regole del profilo, modello,
    impostazioni, layout con testo grande, e tutti i test del budget prima
    e dopo (oggi 270 test Flutter + 3 suite con emulatori).

Piano a passi (un commit e un rilascio per passo, controlli verdi):
E1 Modello e salvataggio. AmaterasuAppearance: dimensione del testo
   (4 livelli: 100%, 110%, 120%, 130%), unità (km/miglia), formato data
   (come la lingua / gg/mm/aaaa / aaaa-mm-gg), formato ora (24 h / 12 h),
   valuta predefinita, valuta di visualizzazione. Salvato in
   viaggiatori/{uid}.appearance (regole: campo facoltativo con valori
   ammessi, test) e copiato nel dispositivo per partire subito.
   Impatto regole: il profilo accetta una mappa in più; nient'altro cambia.
E2 Card "Aspetto" nelle Impostazioni globali, dopo quelle esistenti, con
   il selettore valuta comune e la frase "Gli importi originali rimangono
   invariati". Le card esistenti non cambiano.
E3 Dimensione del testo per tutta l'app (MaterialApp, limite 130%) e
   controllo del layout: test che aprono le pagine principali (sezioni,
   spese, impostazioni, workspace) al 130% su telefono senza
   sovrapposizioni né errori di spazio. Dove qualcosa si sovrappone lo
   correggo solo nelle sezioni nuove; nei moduli approvati lo segno in
   COERENZA.md.
E4 Formato data e ora in un modulo comune usato dalle sezioni nuove
   (tripSectionWhen e simili). Nei moduli approvati (budget, alloggi,
   bucket list) lo applico solo dopo l'ok su COERENZA.md.
E5 Unità km/miglia: salvata ora, usata quando arrivano Mappa, Itinerario
   (distanza in linea d'aria) e Converti. Nessuna schermata la mostra oggi.
E6 Valuta predefinita per le nuove voci: valore iniziale del costo in
   sezioni e alloggi e della valuta nel dialogo "Crea spesa" del budget
   (solo il valore di partenza del pulsante; importi e calcoli uguali).
   Senza scelta resta la valuta del viaggio, come oggi.
E7 Valuta di visualizzazione ovunque: modulo comune "importo mostrato"
   (convertito + "Originale: X" solo se la valuta è diversa).
   - Budget: il selettore della pagina spese parte dal valore di Aspetto;
     cambiarlo lì vale solo per quella pagina e non modifica Aspetto.
     DOMANDA: oggi la scelta del selettore resta salvata nel dispositivo
     per ogni viaggio. Proposta: tenerla così (se l'hai cambiata in quel
     viaggio resta la tua scelta, altrimenti parte da Aspetto). In
     alternativa: ripartire sempre da Aspetto.
   - Budget: "Originale: X" sparisce quando la valuta è la stessa (unico
     cambio di aspetto del budget in questa tappa: è nell'elenco del
     prompt per COERENZA).
   - Alloggi (costo previsto, tassa) e sezioni (costo, prezzo
     d'ingresso, shopping): importo convertito con l'originale sotto.
   - Home e Statistiche non esistono ancora: useranno lo stesso modulo.
     PDF/CSV delle spese: restano nella valuta originale (sono un
     documento dei dati); proposta: aggiungere solo una colonna
     "convertito" se lo vuoi.
   - Stessi tassi Frankfurter e una sola cache: un tasso per coppia di
     valute per sessione (30 minuti come oggi), nessuna chiamata per card.
E8 docs/audit/TEMA-CHIARO.md: impatti di un tema chiaro futuro (token da
   raddoppiare, colori scritti a mano, foto, grafici), senza implementarlo.

Proposta su valuta predefinita e di visualizzazione: tenerle separate
(una serve per scrivere, l'altra per leggere), ma con la valuta di
visualizzazione che, se non scelta, segue quella predefinita: così chi ne
imposta una sola ha già il comportamento atteso.

Decisioni sul piano (25/11/2026): (1) il selettore della pagina spese è
temporaneo: riparte sempre da Aspetto e non modifica Aspetto; (2) in E7 si
toglie "Originale: X" a parità di valuta, con tutti i test del budget
prima e dopo; (3) CSV e PDF restano nella valuta originale, senza colonna
convertita. Condizione per E6 ed E7: riusare gli importi già convertiti
dal budget (stessi tassi, stessa logica), non ricalcolare i totali con
altri tassi, nessun cambio ai calcoli.

## Extra E1 - Preferenze Aspetto (modello e salvataggio)
Modulo comune lib/core/appearance: AmaterasuAppearance (dimensione del
testo 100/110/120/130 %, km/miglia, formato data, formato ora, valuta
predefinita, valuta di visualizzazione che segue la predefinita se non
scelta) e amaterasuAppearanceProvider (parte dalla copia nel dispositivo,
legge il profilo una volta sola, salva nel dispositivo e nel profilo).
Nessuna schermata ancora (arriva in E2).

Impatto sulle regole: il profilo viaggiatori/{uid} accetta un campo in
più, "appearance", modificabile solo dal proprietario e solo con i valori
ammessi (test). Nient'altro del profilo cambia; la cancellazione
dell'account lo elimina con il profilo.

Prove da fare sul sito: nessuna (nessun cambiamento visibile).

## Extra E2 - Pagina Impostazioni > Aspetto
Nuova card "Aspetto" dopo "Lingua" (le card esistenti non cambiano) che
apre una pagina con lo stesso stile della pagina Lingua. Scelte a
pulsanti (lo stesso componente delle sezioni), valute con il pulsante e
il pannello comuni del budget, × per tornare al valore automatico, frase
"Gli importi originali rimangono invariati". Ogni scelta si salva subito;
se il profilo non risponde resta sul dispositivo e compare un avviso.
Gli effetti arrivano nei passi E3 (testo), E4 (date), E6 e E7 (valute).

Prove da fare sul sito:
1. Impostazioni > Aspetto: cambia le scelte, esci e rientra: restano.
2. Da un altro dispositivo con lo stesso account le scelte si ritrovano.

## Extra E3 - Dimensione del testo
L'app applica la dimensione scelta (100-130 %) a tutto il testo (builder
di MaterialApp in lib/app/app.dart). Le altre impostazioni del sistema
restano.

Controllo del layout al 130 % su telefono (390 punti):
- Sezioni nuove (trasporti, prenotazioni, ristoranti, luoghi, note,
  shopping, checklist, ricordi), elenco con un elemento dal nome lungo ed
  editor aperto: nessun errore di spazio (test automatico
  trip_sections_text_scale_test.dart, fa parte dei controlli).
- Pagina spese (budget): nessun errore di spazio.
- Editor degli alloggi (modulo approvato, NON corretto): escono dallo
  spazio le intestazioni delle sezioni a tendina
  (trip_stay_editor_section.dart:34) e la tendina "Prenotato su"
  (trip_stay_booking_section.dart:39). Da mettere in COERENZA.md.
- Bucket list e impostazioni: non provate con il test automatico (servono
  i loro dati di prova); da controllare a mano o in COERENZA.md.

Prove da fare sul sito:
1. Impostazioni > Aspetto > 130 %: tutto il testo dell'app diventa più
   grande, anche dopo aver chiuso e riaperto.
2. Al 130 % sul telefono le sezioni nuove si leggono senza tagli.
3. Editor degli alloggi al 130 %: vedrai i titoli delle sezioni tagliati
   (segnalato, si corregge dopo l'ok su COERENZA.md).

## Extra E4 - Formato di data e ora
Modulo comune AmaterasuDates (lib/core/appearance/amaterasu_dates.dart):
"come la lingua" è esattamente il formato di prima (Material), poi
gg/mm/aaaa, aaaa-mm-gg, ore a 24 o 12 ore (AM/PM). Usato da
tripSectionWhen, dai pulsanti giorno/ora degli editor, dal pannello
"Orari e prezzi" e dalle date delle card di prenotazioni, luoghi e
ricordi. La struttura comune delle pagine delle sezioni si ridisegna
quando cambiano le scelte. Gli orari salvati non cambiano (restano
"HH:mm"): cambia solo come si vedono.

Non ancora applicato (moduli approvati, dopo l'ok su COERENZA.md):
budget, alloggi, bucket list, impostazioni. Restano anche alcune ore
scritte nelle frasi dei trasporti (es. "Arriva in aeroporto entro le
08:00"): sono sezioni nuove, le porto al nuovo formato insieme alla
prossima revisione dei trasporti.

Prove da fare sul sito:
1. Aspetto > aaaa-mm-gg e 12 ore: una prenotazione mostra
   "2027-04-14 · 2:05 PM".
2. "Come la lingua" e 24 ore: tutto come prima.

## Extra E5 - Unità km/miglia
Nessuna schermata mostra oggi distanze: la scelta è già salvata con le
altre preferenze (E1) e verrà usata da Mappa, Itinerario (distanza in
linea d'aria) e Converti. Nessun rilascio per questo passo.

## Extra E6 - Valuta per le nuove voci
Aiuto comune amaterasuDefaultEntryCurrency (lib/core/appearance): la
valuta di partenza è quella di Aspetto se scelta, altrimenti quella di
oggi (del viaggio). Usata da: editor di trasporti, prenotazioni,
ristoranti, luoghi, shopping e alloggi; "Crea spesa" dalle sezioni e
dagli alloggi; nuova spesa dalla pagina spese. Se la voce ha già un
costo, "Crea spesa" parte dalla valuta e dall'importo di quel costo, come
prima. Nel budget cambia solo il valore iniziale del pulsante valuta:
importi, cambi e calcoli invariati. Test del budget prima e dopo: 277 su
277 verdi in entrambi i casi.

Prove da fare sul sito:
1. Aspetto > Valuta per le nuove voci = USD; nuovo trasporto: il costo
   parte in USD.
2. "Crea spesa" su un ristorante senza costo: il dialogo parte in USD;
   su un trasporto con costo in JPY parte in JPY con quell'importo.
3. Senza scelta in Aspetto tutto come prima (valuta del viaggio).

## Extra E7 - Valuta di visualizzazione
Stessi tassi, stessa logica del budget: la scelta del tasso di
BudgetDisplayAmount (tasso bloccato della spesa, poi storico del suo
giorno, poi ultimo) è stata spostata, identica, nella funzione pubblica
budgetDisplayQuote con un solo servizio dei cambi (una cache). Il nuovo
testo comune BudgetShownAmountText la usa per mostrare un importo nella
valuta di Aspetto con "Originale: X" accanto. Nessun totale viene
ricalcolato: si convertono solo gli importi mostrati, uno per uno, come
fa già il budget; calcoli, importi salvati, CSV e PDF invariati.

Dove:
- Budget: la pagina spese parte dalla valuta di visualizzazione di Aspetto
  (se non scelta: quella del viaggio, come prima); il selettore vale solo
  finché resti nella pagina e non modifica Aspetto (prima la scelta
  restava salvata nel dispositivo per viaggio). "Originale: X" non
  compare più a parità di valuta (BudgetDisplayAmount).
- Sezioni: costo previsto di trasporti, prenotazioni e ristoranti, prezzo
  d'ingresso dei luoghi, budget e prezzo reale dello shopping, spesa
  collegata (con il tasso della spesa, come nel budget).
- Alloggi: costo previsto nella card e spesa collegata (solo
  visualizzazione).
- Non convertiti: la riga della tassa di soggiorno (tre importi nella
  stessa frase) e il prezzo di Google del pannello "Orari e prezzi" (già
  convertito nella valuta del viaggio dalla 1.29.0).
- Home e Statistiche non esistono ancora: useranno lo stesso testo.

Test del budget prima e dopo: 277 su 277 in entrambi; i due test che
verificavano "Originale" a parità di valuta sono stati aggiornati alla
decisione del 25/11/2026 (ora verificano che non compaia). Più 4 test
nuovi dell'importo mostrato.

Prove da fare sul sito:
1. Aspetto > Valuta di visualizzazione = USD: un trasporto con costo in
   EUR mostra "Costo previsto: $ … · Originale: € …".
2. Pagina spese: parte in USD; se la cambi in JPY e torni alla pagina,
   riparte da USD. Aspetto resta USD.
3. Una spesa in EUR vista in EUR: nessuna riga "Originale".
4. Totali e quote del budget uguali a prima.

## Extra E8 - Tema chiaro (solo analisi)
Scritto docs/audit/TEMA-CHIARO.md: oggi 51 token fissi pensati per il
tema scuro, 150 colori scritti a mano fuori dal tema e 40 usi di bianco/nero;
servirebbero token a due valori, la pulizia dei colori a mano (nei
moduli approvati dopo COERENZA.md), controlli di contrasto e una scelta
in Aspetto. Nessun codice scritto. Con E8 la Extra E è chiusa.

## Extra F - Assistenza e privacy
Valutazione (regola 1): (a) c'erano Informazioni > Legale (link
all'informativa) e nessun modo per scriverci; (b) nuova card "Assistenza e
privacy" nelle Impostazioni (le card esistenti non cambiano), pagine nuove
in lib/features/support con i componenti comuni (card delle impostazioni,
pannello, pulsanti, modulo link); tabella della conformità in un file
it/en come le novità; (c) regole: nuova raccolta feedback (solo
creazione, al massimo 5 al giorno per utente, nessuna lettura dall'app),
con test.

- Segnala un problema / Suggerisci un'idea: solo il testo scritto, tipo,
  versione e lingua. Nessun registro automatico degli errori, nessuna
  statistica. Si leggono dalla console di Firebase (raccolta feedback).
- Stato dell'app: versione e data dell'ultimo aggiornamento (dal file
  delle novità).
- Informativa privacy: la pagina già online. Termini: non esistono ancora
  (lacuna 1).
- Conformità e normative: tabella con norma, riferimento ufficiale, "Ci
  riguarda?" e come la rispettiamo; solo fatti verificati, il resto "da
  verificare"; frase "Principi che applichiamo, non una certificazione né
  consulenza legale" con la data della verifica.
- Corretta una lacuna trovata: il pannello di ricerca della città ora cita
  la fonte dei dati (Open-Meteo, licenza CC BY 4.0).
- Lacune per il professionista: docs/audit/CONFORMITA-LACUNE.md (10 punti).

Impatto sulle regole: nuova raccolta feedback/{uid_giorno_n}; nessun'altra
regola cambia.

Prove da fare sul sito:
1. Impostazioni > Assistenza e privacy > Segnala un problema: invia; nella
   console di Firebase compare in feedback.
2. Il sesto invio dello stesso giorno dice "Hai già inviato 5 messaggi".
3. Conformità e normative: la tabella si legge in italiano e in inglese.

## Extra G - Caricamento con il sole
Schermata in web/index.html (CSS in linea, nessuna immagine da scaricare):
sole con alone e raggi che girano piano, nome dell'app, colori del tema;
con "riduci animazioni" del sistema resta fermo. Sparisce con una breve
dissolvenza solo quando l'app chiama amaterasuAppReady
(lib/core/web/amaterasu_app_ready.dart): alla pagina di accesso, alla
shell globale (home) o all'apertura di un viaggio; così le rotelline
intermedie dell'avvio restano coperte. Uscita di sicurezza dopo 15 secondi.

Prove da fare sul sito:
1. Apri il sito: vedi il sole, poi direttamente la home (o l'accesso),
   senza rotelline in mezzo.
2. Apri un link di un viaggio: il sole resta fino al viaggio.

## Extra H - Verifica finale (25/11/2026)
Ogni voce del prompt unico v2 confrontata con questo file. Fatto = con
tappa, versione e prove; il resto ha una tappa qui sotto.

| Voce del prompt | Stato | Dove |
|---|---|---|
| Passo 0 (regole fisse) e Passo 1 (INVENTARIO-UI, COSTI, API-ESTERNE, DIRETTIVE-UI) | fatto | docs/ |
| U1 componenti condivisi | fatto | 1.24.0 |
| 1b (filtri, valuta, nomi, allergeni, luoghi, foto, checklist) | fatto | 1.25.0-1.26.0 |
| Trasporti, Prenotazioni, Ristoranti, Luoghi, Alloggi, Note, Shopping | fatto | 1.27.0-1.33.0 |
| Ricordi, esportazione CSV/PDF spese | fatto (piano precedente) | 1.22.0, 1.23.0 |
| Link ovunque (sezioni, voci checklist, spese) | fatto | 1.34.0, 1.35.0 |
| URL nel testo delle note cliccabili | fatto | 1.35.1 |
| Crea spesa dalle sezioni (tipo, per persona, Tutti, origine) | fatto; selezione multipla non riprodotta, in attesa dei tuoi passi | 1.35.0 |
| Extra A novità e versioni | fatto | 1.36.0 |
| Extra B PWA | fatto | 1.37.0 |
| Extra C fuso orario per città | fatto; migrazione non necessaria | 1.38.0 |
| Extra D categorie personalizzate e filtro | fatto (spese: solo in K) | 1.39.0, 1.40.0 |
| Extra E Aspetto (E1-E8) | fatto | 1.41.0-1.46.0, TEMA-CHIARO.md |
| Extra F assistenza e privacy | fatto; lacune in CONFORMITA-LACUNE.md | 1.47.0 |
| Extra G caricamento | fatto | 1.48.0 |
| Nuova tappa 1 Converti, Meteo, Info paese | fatto | 1.49.0, 1.50.0, 1.51.0 |
| Nuova tappa 2 Cerca globale | fatto (2a, 2b, 2c) | 1.52.0, 1.53.0, 1.54.0 |
| Nuova tappa 3 Calendario .ics, Statistiche, PDF del viaggio | fatto (3a, 3b, 3c) | 1.55.0, 1.56.0, 1.57.0 |
| Nuova tappa 4 Audit Trail (analisi, poi costruzione se non tocca moduli approvati) | da fare | - |
| K BUDGET-2 (solo analisi) | da fare | - |
| L MAPPA-ITINERARIO (solo documento) | da fare | - |
| Tabella COERENZA.md, HOME-VIAGGIO.md | da fare, poi stop per il tuo ok | - |

Voci rimaste aperte dentro tappe fatte (da riprendere):
- Ore nelle frasi dei trasporti ("Arriva in aeroporto entro le 08:00")
  ancora a 24 ore: prossima revisione dei trasporti.
- Riga della tassa di soggiorno non convertita nella valuta di
  visualizzazione (tre importi nella stessa frase).
- Formato data/ora e controllo al 130 % nei moduli approvati (budget,
  alloggi, bucket list, impostazioni): in COERENZA.md.
- Editor degli alloggi al 130 %: titoli e tendina escono dallo spazio
  (COERENZA.md).
- Termini d'uso da scrivere (CONFORMITA-LACUNE.md). Le segnalazioni si
  cancellano con l'account dalla 1.49.1.
- Spese con categorie personalizzate multiple: analisi in K.

## Nuova tappa 1a - Converti
Valutazione (regola 1): (a) esistevano il selettore valuta e la logica dei
tassi del budget (budgetDisplayQuote, una cache); (b) Converti li riusa
identici; l'intestazione delle pagine di Altro è stata estratta senza
cambiamenti da TripSectionScaffold (TripSectionHeader) e i blocchi a
tendina sono quelli delle sezioni; (c) nessuna regola, nessuna API nuova,
nessun dato salvato.

- Valute: dalla valuta del viaggio a quella di visualizzazione di Aspetto
  (o EUR/USD), inversione, risultato con fonte e data del cambio.
- Unità: °C/°F, km/miglia, kg/libbre in entrambi i versi.
- Taglie delle scarpe EU/UK/US uomo/donna, tabella indicativa.
- Mancia: conto, 0-20 %, persone: mancia, totale e quota a testa.
- Provata al 130 % su telefono senza errori di spazio.

Prove da fare sul sito:
1. Altro > Converti: 100 nella valuta del viaggio mostra il cambio e
   "Cambio Frankfurter del …".
2. Unità: 10 km = 6.21 mi. Mancia: 60 al 10 % in 3 = 22 a testa.

## Passo 1.49.1 - Segnalazioni cancellate con l'account
Valutazione (regola 1): (a) ogni segnalazione ha già il campo createdByUid
(controllato dalle regole) e l'id inizia con l'uid: nessun cambio di
formato; (b) si aggiunge la cancellazione nella stessa operazione unica
(batch) che toglie il profilo, con ok esplicito sul modulo approvato;
(c) tocca account_deletion_service.dart (12 righe) e la regola di
feedback; test: impostazioni, regole, budget prima e dopo.

- Regole: l'autore può elencare (solo con il filtro sul proprio uid) e
  cancellare i propri messaggi; nessun altro li legge o li cancella;
  la lettura singola e la modifica restano vietate.
- Informativa privacy: nuova sezione 7.1 "Segnalazioni e idee" (it/en),
  data aggiornata. Conformità: riga "Segnalazioni" aggiornata, lacuna 3
  risolta.

Prove da fare sul sito:
1. Con un account di prova invia una segnalazione, poi cancella
   l'account: in console Firebase la raccolta feedback non ha più i
   suoi messaggi.

## Nuova tappa 1b - Meteo
Valutazione (regola 1): (a) non esisteva nulla di meteo; esistevano la
funzione dei cambi con chiamata esterna dal server, i blocchi a tendina
delle sezioni, TripSectionHeader e AmaterasuLinkChip; (b) si riusano
identici; la nuova funzione getTripWeather segue lo schema delle altre
(verifica dell'email, solo membri, europe-west1); (c) nessuna modifica a
firestore.rules (la cache weatherCache è già negata ai client dalla regola
finale "nega tutto"), una riga in trip-duplication-policy (cache non
copiata, come le sezioni); deleteTrip la cancella già con le altre
sottoraccolte. Test: funzioni (sintesi, periodi del clima, giorno del
viaggio, duplicazione), app (regole, link, dati, pagina, errori, 130 %).

- Pagina Altro > Meteo: aggiornamento, "Apri su 3B Meteo", previsioni per
  16 giorni con la scritta "Viaggio" sui giorni del viaggio (si sceglie un
  giorno), ora per ora con alba, tramonto, vento e UV, "Cosa mettere"
  (regole fisse), "Aria e pollini", "Clima tipico del periodo", fonte.
- Viaggio oltre i 16 giorni: avviso, meteo di questi giorni e clima.
- Errori: senza destinazione sulla mappa un messaggio; servizio fermo
  "Riprova" oppure i dati dell'ultimo aggiornamento con avviso.
- Funzioni sul server: 33 (controllo della pubblicazione aggiornato).

Prove da fare sul sito:
1. Altro > Meteo in un viaggio a Roma: giorni con temperature, "Apri su
   3B Meteo" apre la pagina di Roma.
2. Riaprire la pagina nella stessa sessione non ricarica (nessuna rotella).
3. Viaggio all'estero: "Apri su 3B Meteo" apre la home con la ricerca.

## Nuova tappa 1c - Info paese
Valutazione (regola 1): (a) non esisteva nulla sui paesi; esistevano il
caricamento di file JSON dell'app (Conformità, novità), i blocchi a
tendina, TripSectionHeader e AmaterasuLinkChip; (b) si riusano identici;
(c) nessuna regola, nessuna funzione, nessuna API dall'app; un file nuovo
in assets/country_info/ e lo script tool/build_country_info.mjs. Test:
file generato (fonte, licenza, data, Italia), pagina, 130 %.

- Dati da Wikidata (CC0 1.0), rigenerati con
  `node tool/build_country_info.mjs` (serve la rete; lo script non
  scrive il file se i dati dell'Italia non tornano). 255 paesi.
- Pagina Altro > Info paese: avviso "verifica sempre su fonti
  ufficiali", scelta del paese (parte da quello della destinazione),
  prefisso, emergenze, prese, tensione, lato di guida, fusi, ognuna con
  "Fonte: Wikidata (CC0 1.0) · dati del ..."; le voci senza dati non
  compaiono. Schede ufficiali: Viaggiare Sicuri (codice ISO a 3 lettere),
  consolati Farnesina, scheda Wikidata.
- Acqua potabile, salute, documenti, visti e requisiti d'ingresso: nessuna
  fonte aperta affidabile, solo il link ufficiale (come chiede il prompt).
- REST Countries non usata: la versione libera ora risponde "deprecated".

Prove da fare sul sito:
1. Altro > Info paese in un viaggio in Giappone: +81, prese tipo A e B,
   100 V, guida a sinistra; "Viaggiare Sicuri" apre la scheda del paese.
2. Cambiare paese dalla tendina: le voci cambiano.

## Nuova tappa 2 - Cerca globale
Valutazione (regola 1):
(a) Esiste già: "Collega a un elemento" delle Note
(tripNoteLinkTargetsProvider) legge una volta sola, su richiesta, gli
elementi di alloggi, trasporti, prenotazioni, ristoranti e luoghi con gli
stessi store delle sezioni; gli store di note e checklist leggono solo le
condivise più le proprie private (due richieste, regole e test). Esistono
anche TripSectionHeader, i chip di scelta delle sezioni, le preferenze
locali (SharedPreferences) e i percorsi di ogni sezione.
(b) Si riusano gli stessi store identici (stessa lettura che l'utente fa
aprendo la sezione: nessuna copia dei dati altrove, nessun indice salvato,
nessuna API); un nuovo modulo lib/features/trips/tools/search con l'elenco
fisso dei campi di testo in cui cercare (nomi, titoli, testi, note,
indirizzi, città, compagnia, codici di prenotazione, voci delle
checklist); esclusi codice porta, Wi-Fi, telefono, email, link e
identificativi.
(c) Tocca solo file nuovi più la voce di Altro e il percorso; nessuna
regola, nessuna funzione. Test: estrazione del testo, ricerca senza
accenti, filtro per sezione, ricerche recenti, privacy (note private di
altri mai presenti perché lo store non le legge), tocco che porta alla
sezione, 130 %.

Piano a passi (un rilascio ciascuno):
- 2a: Altro > Cerca: alloggi (solo lettura, modulo approvato non
  toccato), trasporti, prenotazioni, ristoranti, luoghi, note, shopping,
  checklist, ricordi; dati letti alla prima ricerca e tenuti per la
  sessione (pulsante "Aggiorna"), risultati a pagine da 20, filtro per
  sezione, ricerche recenti sul dispositivo; il tocco apre la sezione (la
  checklist apre la lista).
- 2b: evidenziare l'elemento toccato nelle sezioni nuove (elenco comune
  TripSectionList); negli alloggi solo dopo il tuo ok (modulo approvato).
- 2c: spese e bucket list in sola lettura con le letture già esistenti,
  senza cambiare quei moduli (le spese private solo le proprie).

### Passo 2a - fatto (1.52.0)
- lib/features/trips/tools/search: testo cercabile (elenco fisso dei
  campi; anche le voci delle checklist, salvate per identificativo),
  confronto senza maiuscole né accenti e con tutte le parole, sorgenti
  (stessi store delle sezioni, alloggi con il loro repository in sola
  lettura), ricerche recenti (8, per utente e viaggio, sul dispositivo),
  pagina con filtro per sezione, pagine da 20, "Aggiorna".
- Costi: nessuna lettura finché non si scrive; poi una lettura di ogni
  sezione per sessione (la stessa che farebbe aprire la sezione), nessun
  ascolto attivo, nessuna API. Firestore non permette di cercare nel
  testo: le letture a pagine riguardano la vista dei risultati.
- Test: testo e privacy dei campi (codice porta, Wi-Fi, telefono, link,
  identificativi), confronto, recenti, lettura con gli store (solo ciò che
  restituiscono), pagina, apertura della sezione e della checklist, 130 %.

Prove da fare sul sito:
1. Altro > Cerca, scrivi il nome di un hotel o un codice di prenotazione:
   il risultato apre la sezione giusta.
2. Una nota privata di un altro viaggiatore non compare mai.
3. Le ricerche recenti restano dopo aver riaperto la pagina.

### Passo 2b - fatto (1.53.0)
Valutazione (regola 1): (a) l'elenco comune TripSectionList è usato da
tutte le sezioni nuove (trasporti, prenotazioni, ristoranti, luoghi,
note, shopping, checklist, ricordi); (b) il risalto si aggiunge lì una
volta sola (nessuna pagina cambia): un segno in memoria
(tripSectionFocusProvider) messo da Cerca, letto e cancellato dall'elenco;
(c) tocca trip_section_list.dart (diviso con il file part
trip_section_list_item.dart, la voce spostata senza cambiamenti) e
trip_section_focus.dart nuovo; test: tutti quelli delle sezioni prima e
dopo (600 passati) più quelli nuovi.

- L'elenco scorre fino all'elemento (anche se è in fondo: le card si
  costruiscono man mano), bordo arancio per 3 secondi, poi normale.
- Se i filtri lo nascondono: avviso "nascosto dai filtri attivi".
- Alloggi: si apre la pagina senza risalto (modulo approvato: serve il tuo
  ok per aggiungerlo). Checklist: si apre già la lista.

Prove da fare sul sito:
1. Cerca un luogo salvato in fondo all'elenco: la pagina scorre fino a lui
   e lo mostra con il bordo.
2. Con un filtro attivo che lo nasconde compare l'avviso.

### Passo 2c - fatto (1.54.0)
Valutazione (regola 1): (a) spese e bucket list (moduli approvati) hanno
già le loro letture: BudgetApi.sharedExpenses (solo le spese condivise in
cui partecipo) e privateExpenses (solo le mie), BucketActivityRepository
.fetchPage (a pagine, al massimo 50); (b) Cerca le chiama così come sono,
in sola lettura, nel nuovo file trip_search_approved.dart; nessun file di
quei moduli cambia; (c) test della lettura con il budget finto e della
navigazione.

- Spese: titolo e note (stesso elenco fisso dei campi). Il tocco apre la
  pagina spese, senza risalto (modulo approvato).
- Bucket list: nome, città, paese, note, categoria personalizzata,
  indirizzo; letta a pagine da 50 (al massimo 40 pagine). Il tocco apre la
  bucket list, senza risalto.
- Costi: come per 2a, una lettura per sessione solo dopo la prima ricerca.

Prove da fare sul sito:
1. Cerca il titolo di una spesa: apre la pagina spese.
2. Una spesa privata di un altro non compare mai.
3. Cerca un'attività della bucket list: apre la bucket list.

## Nuova tappa 3 - Calendario, Statistiche, PDF
Valutazione (regola 1):
(a) Esistono: il modulo comune lib/core/files (scarica un testo, apre una
pagina da stampare o salvare come PDF; usato da spese e checklist), gli
store delle sezioni e la lettura su richiesta di Cerca, AmaterasuZoneClock
(scarto UTC di un fuso IANA in un giorno, ora legale compresa), le
etichette dei trasporti (TripTransportLabels.title), i chip comuni e i
calcoli del budget (per le statistiche delle spese, 3b).
(b) Si riusano identici: download e stampa da lib/core/files, store delle
sezioni in sola lettura, scarto dei fusi da AmaterasuZoneClock e dagli
scarti già salvati nei trasporti. Nuovo modulo
lib/features/trips/tools/export. Nessun modulo approvato cambia (alloggi
e budget solo letti).
(c) Nessuna regola, nessuna funzione, nessuna API. Test: scrittura del
.ics (righe CRLF, testi protetti, righe lunghe spezzate), orari con
scarto (UTC), con fuso (UTC) e senza (ora locale), giornate intere,
annullati esclusi, scelta delle categorie, pagina, 130 %.

Piano a passi (un rilascio ciascuno):
- 3a: Altro > Esporta: calendario .ics con scelta di alloggi, trasporti,
  prenotazioni, ristoranti; alloggi come giornate intere dal check-in al
  check-out; trasporti con lo scarto salvato; prenotazioni e ristoranti
  con il fuso della città, altrimenti ora locale; senza ora: giornata
  intera; annullati esclusi.
- 3b: Altro > Statistiche (notti, paesi e città, spese per categoria e per
  persona leggendo il budget, trasporti per tipo, ristoranti provati,
  luoghi; tre numeri e una ciambella).
- 3c: PDF del viaggio in Esporta (riepilogo e link alla cartella dei
  ricordi) con la stampa del browser.

### Passo 3a - fatto (1.55.0)
- lib/features/trips/tools/export: scrittura del .ics (RFC 5545: CRLF,
  testi protetti, righe spezzate a 75 byte, UID stabile per elemento così
  un nuovo import aggiorna invece di duplicare in molti calendari),
  eventi dalle sezioni, dati letti solo premendo "Scarica", pagina
  Altro > Esporta con la scelta delle 4 categorie.
- Orari: trasporti con lo scarto salvato, prenotazioni e ristoranti con il
  fuso della città (AmaterasuZoneClock, ora legale compresa), tutti in
  UTC; senza fuso ora locale; senza ora giornata intera; alloggi come
  giornate dal check-in al check-out; fine mancante: un'ora dopo.
- Bottone comune AmaterasuPrimaryButton: il testo ora è Flexible (va a
  capo, al massimo 2 righe) perché al 130 % su telefono usciva dal
  bottone; quando il testo ci sta l'aspetto è identico. Tutti i test
  passano.

Prove da fare sul sito:
1. Altro > Esporta > Scarica calendario: il file si apre in Google
   Calendar con il volo all'ora giusta nel fuso di partenza e d'arrivo.
2. Togli "Hotel e alloggi": gli alloggi non ci sono.

### Passo 3b - fermo in attesa di una scelta (25/11/2026)
Valutazione (regola 1) per le spese delle Statistiche: (a) i totali per
categoria nella valuta del viaggio esistono solo dentro il cruscotto del
budget (budget_category_dashboard_summary.dart, metodo _summary di circa
320 righe con TODO(audit), più i cambi in
budget_category_dashboard_rates.dart), privati della schermata; (b) per
riusarli identici vanno estratti in un modulo condiviso del budget senza
cambiare il comportamento, con i test del budget prima e dopo; (c) tocca
un modulo approvato: serve il tuo ok.
Scelte proposte:
- A: estrarre il calcolo dei totali (categoria e persona, stessi tassi e
  stessa logica) in un modulo condiviso del budget e usarlo nelle
  Statistiche e nel cruscotto, che resta identico.
- B: le Statistiche mostrano notti, paesi e città, trasporti per tipo,
  ristoranti provati, luoghi; per le spese solo il totale già mostrato
  dal budget e il pulsante "Apri il cruscotto spese".
Resto della tappa 3 (3c PDF del viaggio) indipendente: si può fare prima.

### Passo 3b - fatto (1.56.0), scelta A
- Estrazione (modulo approvato, con il tuo ok): il calcolo dei totali del
  cruscotto delle categorie (ciclo sulle spese, conversione, esclusioni,
  quota mia, anticipi, giorni) e la scelta del tasso di ogni spesa
  (bloccato sulla spesa, altrimenti storico del giorno) sono ora in
  lib/features/trips/budget/presentation/budget_category_totals.dart; il
  cruscotto li chiama. Codice spostato senza cambiamenti; in più il totale
  per persona, calcolato con la stessa regola della quota mia (un test
  controlla che per me coincidano).
- Test del budget prima e dopo: 281 test Flutter del budget, 693 in
  tutto e tutte le suite con emulatori (regole, privacy, integrazione
  budget e le altre) con righe di risultato identiche al confronto.
- Statistiche (Altro > Statistiche): tre numeri (notti, città, spese
  condivise), ciambella per categoria con BudgetCategoryChart e i colori
  del budget, spese per persona con lo username del budget, paesi e città
  degli alloggi, trasporti per tipo, ristoranti provati con voto medio,
  luoghi visitati. Spese: condivise in cui partecipo, filtri predefiniti
  del cruscotto (annullate escluse), valuta del viaggio, stessi tassi;
  senza budget leggibile le altre statistiche restano.
- Risalto negli alloggi: non fatto, voce 1 di docs/audit/COERENZA.md
  (creato con le voci già rimandate al giro finale).

Prove da fare sul sito:
1. Altro > Statistiche: il totale delle spese condivise è uguale a quello
   del cruscotto spese (vista "Gruppo", senza filtri) nella valuta del
   viaggio.
2. Le spese per persona sommano le quote di ciascuno.

### Passo 3c - fatto (1.57.0)
- Esporta > PDF del viaggio: pagina HTML aperta in una nuova scheda con
  la stampa del browser ("Salva come PDF"), come i PDF del budget e delle
  checklist (lib/core/files). Titolo, destinazione e date, tabelle di
  alloggi, trasporti, prenotazioni e ristoranti prenotati in ordine di
  data (annullati esclusi), date e ore nel formato di Aspetto; Ricordi:
  link della cartella Google Drive del viaggio e degli album (solo
  indirizzi http/https diventano link). Dati letti solo premendo.
- Avviso se il browser blocca la nuova scheda.
- TODO(audit) nel file: lo stile di stampa è lo stesso del budget e delle
  checklist, da unificare in un modulo comune nel giro finale.

Prove da fare sul sito:
1. Altro > Esporta > Apri il PDF: si apre la stampa con il riepilogo;
   "Salva come PDF" crea il file con i link cliccabili.

## Tappa 4, K, L, COERENZA, HOME-VIAGGIO - documenti (25/11/2026)
Solo documenti, nessun codice, nessun rilascio:
- docs/audit/AUDIT-TRAIL.md: cosa esiste (createdByUid sì, updatedByUid
  no; budget con registri dal server e listBudgetHistory), tre opzioni
  A/B/C con regole, costi, privacy; proposta B + budget in sola lettura.
- docs/audit/BUDGET-2.md: 9 punti con cosa tocca, rischi sui soldi,
  lavoro e ordine; scontrini nel Drive di chi allega, solo il link nella
  spesa.
- docs/design/MAPPA-ITINERARIO.md: dati, tre viste, zone senza chiamate
  in più, mappa, ordine di costruzione.
- docs/audit/COERENZA.md: tabella dei moduli approvati a gruppi (A spese,
  B home globale, C home del viaggio, D alloggi, E bucket list, F
  impostazioni, G componenti).
- docs/design/HOME-VIAGGIO.md: piano tecnico per fase.
FERMO: attendo il tuo ok su ciascun documento prima di costruire.

## Decisioni del proprietario (25/11/2026) e ordine
- Audit Trail: opzione B (registro dal server per le sezioni nuove; spese
  con lo Storico del budget esistente; note e checklist private mai nel
  registro; "Utente eliminato"; informativa nello stesso rilascio).
- COERENZA: tutti i gruppi approvati; ordine G, F, E, D, B, C (con la
  home), A per ultimo con test del budget prima e dopo ogni passo; A4:
  verificare il significato dei totali prima di rinominare; E1: "+" in
  alto a destra. Aggiunte: F - pagina Aspetto rifatta sul modello della
  pagina Privacy (frase introduttiva, card con icona, titolo e
  descrizione); G - cestino al posto del menu "⋮" quando contiene solo
  "Elimina" (doppia conferma invariata); Impostazioni - card a tutta
  larghezza su schermo largo.
- HOME-VIAGGIO: approvata com'è.
- BUDGET-2: approvati 1-3, 2, 4, 5, 7, 8; rimandati alla 2.x i punti 6 e
  9; budget di gruppo impostato solo dal proprietario.
- MAPPA-ITINERARIO: approvata; zone da Google solo se non cambia la
  categoria di prezzo (verificare prima, altrimenti solo la città);
  itinerario NON copiato quando si duplica il viaggio.
- Ordine generale: Audit Trail (B) → Coerenza → Home → Budget 2 →
  Itinerario → Mappa. Un rilascio per passo, controlli completi prima.

## Audit Trail (B) - valutazione (regola 1)
(a) Esistono: createdByUid e updatedAt (ora del server) obbligati dalle
regole nel modulo comune delle sezioni (sectionBase); tutte le scritture
dall'app passano da FirestoreTripSectionStore tranne due (voci delle
checklist: trip_checklist_entries.dart; voti dei ristoranti:
trip_restaurant_vote_service.dart); nessun file degli indici (online: 0
indici composti); firebase-functions 7 con trigger Firestore v2. I trigger
non danno in modo affidabile l'utente dell'app (tipi: service_account,
api_key, system, unauthenticated, unknown): l'autore viene da
updatedByUid obbligato dalle regole.
(b) Si aggiunge updatedByUid nel modulo comune (store, regola
sectionBase) e nelle due scritture dirette; un trigger unico
recordTripAudit (europe-west1) per le raccolte delle sezioni nuove; regola
auditTrail di sola lettura per i membri; 3 indici composti; pagina in
Altro. Eliminazione: lo store scrive prima updatedByUid e poi cancella,
così il registro sa chi ha eliminato. Scritture del server (deleteTrip,
duplicazione) ignorate dal trigger. Nomi: membro senza profilo = "Utente
eliminato", non più membro = "Ex viaggiatore".
(c) Tocca: modulo comune delle sezioni, regole delle sezioni (test in
rules-tests/sections da aggiornare con updatedByUid), funzioni (34),
indici, duplicazione (auditTrail escluso), informativa privacy. Alloggi,
bucket list e budget non cambiano.

### Audit Trail (B) - fatto (1.58.0)
- Regole: sectionBase chiede updatedByUid uguale a chi scrive (creazione
  e modifica); auditTrail in sola lettura per i membri, nessuna scrittura
  per nessuno. Test: 75 delle sezioni (aggiornati con la firma) + 2 nuovi
  del registro.
- App: lo store comune, le voci delle checklist e i voti dei ristoranti
  firmano ogni scrittura; l'eliminazione firma e poi cancella.
- Server: recordTripAudit (trigger, europe-west1) per le 8 raccolte delle
  sezioni nuove; ignora privati, scritture del server, modifiche senza
  cambiamenti, viaggi eliminati; campi sensibili solo "•", testi a 200
  caratteri. 34 funzioni. Indici: 3 (sezione, persona, azione + data) in
  firestore.indexes.json. Registro escluso dalla copia del viaggio,
  cancellato con il viaggio.
- Pagina Altro > Audit Trail: filtri con il pannello condiviso, pagine da
  30, nomi con lo username, "Utente eliminato" (membro senza profilo) ed
  "Ex viaggiatore"; spese: rimando allo Storico del budget (invariato).
- Informativa privacy: sezione 7.2.
- Limite noto: l'autore di un'eliminazione è chi ha firmato per ultimo
  (l'app firma subito prima di eliminare).

Prove da fare sul sito:
1. Modifica un trasporto: in Altro > Audit Trail compare "<tu> ha
   modificato" con il campo prima → dopo.
2. Una nota privata modificata non compare.
3. Filtro per persona e sezione.

## Punto di ripresa (25/11/2026, dopo la 1.58.0)
Fatto: Audit Trail (B), pubblicato 1.58.0+64 (34 funzioni, 3 indici).
Prossimo passo: COERENZA gruppo G (componenti comuni: pulsanti
principale/secondario/terziario, pannello dal basso o finestra unica,
selettore valuta, stampa comune, testi it/en, cestino al posto di "⋮"
quando contiene solo "Elimina"), poi F (con la pagina Aspetto sul modello
della Privacy e le card a tutta larghezza su schermo largo), E, D, B, C
con la home, A per ultimo. Poi Budget 2, Itinerario, Mappa.

## COERENZA gruppo G - passo G1 (1.59.0)
Valutazione (regola 1): (a) i componenti esistono già nel core
(AmaterasuButton con i quattro tipi, showAmaterasuSheet, confirmAmaterasuAction
con doppia conferma) ma erano poco usati; (b) si usano identici al posto
dei pulsanti scritti a mano nelle parti non approvate (sezioni nuove,
strumenti, checklist, Link utili); il menu "⋮" delle sezioni con la sola
voce Elimina diventa un cestino (stessa chiave, stessa doppia conferma);
G5: testi scritti nel codice spostati in lib/l10n (accesso, logout,
cartella Drive; "Il mio Drive" resta perché è salvato con l'archivio);
(c) nessun calcolo, dato o regola; test delle sezioni aggiornati (il
cestino apre subito la conferma).
- Resta per i passi seguenti di G: G3 selettore valuta comune, G4 stampa
  comune; G2 (pannello unico) si applica modulo per modulo nei gruppi F-A.

## COERENZA gruppo G - passo G3 (1.59.1)
Valutazione (regola 1): (a) il pannello comune pickBudgetCurrency esisteva (dialogo spese); barra delle spese e budget personale avevano copie con lo stesso elenco di valute, lo stesso codice lingua e lo stesso risultato (normalize = maiuscolo per i codici supportati); unica differenza useRootNavigator; (b) opzione facoltativa useRootNavigator nel modulo comune, le due copie lo chiamano; (c) budget (modulo approvato, gruppo G approvato): 281 test Flutter del budget prima e dopo, suite con emulatori identiche al confronto riga per riga. TODO(audit) C7 risolta.

## Bozza funzionante di Itinerario e Mappa (1.60.0, prima del gruppo G)
Valutazione (regola 1), riuso in una riga: interfaccia
TripItineraryRepository con implementazione demo in memoria;
TripSearchSection (icona, nome, percorso), TripSectionChip +
TripSectionLabels.status, AmaterasuFilterBar/showAmaterasuFilterSheet,
AmaterasuFoldSection/TripSectionBlock, showAmaterasuSheet, AmaterasuButton,
AmaterasuEditButton, confirmAmaterasuAction (doppia conferma),
AmaterasuLinkOpener.openMaps + AmaterasuWebLink.googleMaps, km/miglia di
Aspetto, AmaterasuDates, share_plus, google_maps_flutter con lo stile
scuro (spostato identico in lib/core/maps), TripSectionHeader (+ indirizzo
di ritorno facoltativo), schema della memoria della vista.

Reale: schermate, filtri, gruppi per zona, avvisi, distanze, link a
Google Maps, condivisione, editor, mappa Google con pin raggruppati e
linee tratteggiate, preferenza della vista. Solo demo: i dati (Kyoto, 4
giorni da oggi, 14 voci, 3 elementi fuori programma, Yato e Leo), il
salvataggio (in memoria, si perde ricaricando), le miniature (solo
icone), "Apri la sezione" (apre la sezione vera, dove gli elementi di
esempio non esistono). Nessuna scrittura su Firestore, nessuna raccolta,
regola, funzione o API nuova.

Decisioni aperte (da decidere tu):
1. Riordino e orari: nella bozza una voce trascinata perde l'ora; in
   alternativa si riordinano solo le voci senza ora.
2. Durata delle voci: senza ora di fine la sovrapposizione è "meno di
   un'ora tra due inizi"; serve un'ora di fine (facoltativa)?
3. Chi modifica ed elimina le voci: tutti i membri o autore e OWNER?
4. Il filtro "persona": chi ha aggiunto la voce o chi se ne occupa?
5. "Fatto invece": testo libero (bozza) o anche un elemento di una
   sezione?
6. Vista predefinita: ricordata (bozza) o automatica (linea del tempo
   prima del viaggio, giorno per giorno durante) come nel documento?
7. Trasporti sulla mappa: solo partenza (bozza) o partenza e arrivo?
8. Mappa: gli elementi non in programma spariscono con il filtro giorno
   (bozza); va bene?
9. Miniature con le foto di Google: quando chiederle (costo per foto)?
10. Zone da Google: verificare che il campo quartiere non cambi la
    categoria di prezzo della richiesta; altrimenti solo la città.
11. "Aggiungi nuovo dall'itinerario" che crea l'elemento nella sezione:
    solo ristoranti e luoghi come nel documento?

Prove da fare sul sito:
1. Itinerario: le tre viste, i gruppi per zona apribili, l'avviso del
   giorno 2, "Fatto invece" barrato, "Apri a piedi su Google Maps".
2. Giorno per giorno: Riordina, Condividi il giorno, elimina (due
   conferme), aggiungi una voce libera; ricaricando torna l'esempio.
3. Altro > Mappa: 16 luoghi, gruppi che si aprono avvicinandosi, riquadro
   con "Apri su Maps".

## COERENZA gruppo G - passo G4 (1.60.1)
Valutazione (regola 1): (a) tre stampe con tre copie di pagina, stile e protezione dei testi (budget_export_writer, trip_checklist_tools, trip_pdf_summary); (b) modulo comune lib/core/files/amaterasu_print_page.dart (pagina, stile unico, protezione & < > ", tabella) usato da tutte e tre; nella stampa delle spese cambiano solo titolo 16 -> 18 e spazio sotto le tabelle 18 -> 14; (c) budget (approvato, gruppo G approvato): 281 test prima e dopo, suite con emulatori identiche. TODO(audit) del PDF risolto. Registrate anche le 11 decisioni sulla bozza in docs/design/MAPPA-ITINERARIO.md (sezione 8).

## Correzioni alla bozza e sole di caricamento (1.60.2)
Valutazione (regola 1): la Bucket List ha l'intestazione scritta nella pagina (modulo approvato), non un componente; il componente comune delle pagine nuove è TripSectionHeader: esteso con più azioni e una riga piccola sotto il titolo (default invariati). Viste: controllo segmentato comune TripSectionSegments (usato anche dal selettore delle sezioni, aspetto uguale; solo icone in Itinerario quando le etichette non ci stanno). Filtri: AmaterasuFilterIconButton (icona con il numero). Mappa: gesto a due dita della mappa della destinazione spostato identico in lib/core/maps e usato anche qui (rotazione, inclinazione), pulsante Nord, inquadratura di tutti i pin all'apertura e a ogni cambio di filtro o giorno. Caricamento: nuovo componente AmaterasuLoader (il sole di index.html con i colori del tema) al posto di 73 indicatori di attesa; restano le 4 barre che mostrano un avanzamento reale (budget per categoria, budget personale, checklist, card del viaggio). Test del budget prima e dopo: 281, suite con emulatori identiche. Documento MAPPA-ITINERARIO: principio fisso (l'itinerario lo costruisce l'utente) e funzione "Aggiungi all'itinerario" dalle card (solo documento).
Punti sistemati (file, numero di indicatori):
  - core/places/widgets/amaterasu_place_search_field.dart (1)
  - core/time_zones/amaterasu_zone_field.dart (1)
  - core/widgets/buttons/amaterasu_primary_button.dart (1)
  - features/auth/presentation/pages/auth_gate.dart (3)
  - features/auth/presentation/pages/google_auth.dart (1)
  - features/settings/presentation/pages/account/account_delete_dialog.dart (1)
  - features/settings/presentation/pages/account/account_email_page.dart (1)
  - features/settings/presentation/pages/account/account_password_page.dart (1)
  - features/settings/presentation/pages/data/data_connection_page.dart (1)
  - features/settings/presentation/pages/data/data_sync_settings_page.dart (1)
  - features/settings/presentation/pages/information/information_licenses_page.dart (1)
  - features/settings/presentation/pages/profile/profile_page.dart (2)
  - features/settings/presentation/pages/profile/profile_username_dialog.dart (1)
  - features/support/presentation/compliance_page.dart (1)
  - features/trips/budget/presentation/budget_category_dashboard.dart (3)
  - features/trips/budget/presentation/budget_create_dialog.dart (1)
  - features/trips/budget/presentation/budget_expense_controls.dart (1)
  - features/trips/budget/presentation/budget_expense_history.dart (1)
  - features/trips/budget/presentation/budget_expense_list.dart (1)
  - features/trips/budget/presentation/budget_history_view.dart (1)
  - features/trips/budget/presentation/budget_reimbursements_panel.dart (3)
  - features/trips/budget/presentation/budget_revision_panel.dart (4)
  - features/trips/budget/presentation/budget_user_settlement_summary.dart (2)
  - features/trips/budget/presentation/personal_trip_budget_card.dart (3)
  - features/trips/presentation/pages/create_trip/cloud_archive/google_drive_folder_browser_page.dart (3)
  - features/trips/presentation/pages/create_trip/cloud_archive/trip_cloud_archive_page.dart (1)
  - features/trips/presentation/pages/create_trip/destination/trip_destination_page.dart (1)
  - features/trips/presentation/pages/create_trip/destination/widgets/destination_world_map.dart (1)
  - features/trips/presentation/pages/invite/trip_invite_page.dart (1)
  - features/trips/presentation/pages/trips_page.dart (1)
  - features/trips/presentation/pages/workspace/bucket_list/bucket_activity_editor_part.dart (2)
  - features/trips/presentation/pages/workspace/bucket_list/bucket_method_page_view.dart (1)
  - features/trips/presentation/pages/workspace/expenses/trip_expenses_page.dart (1)
  - features/trips/presentation/pages/workspace/more/checklists/trip_checklist_detail_page.dart (1)
  - features/trips/presentation/pages/workspace/more/hotels/editor/trip_stay_editor.dart (1)
  - features/trips/presentation/pages/workspace/more/hotels/trip_hotels_page.dart (1)
  - features/trips/presentation/pages/workspace/more/hotels/widgets/trip_stay_expense_actions.dart (1)
  - features/trips/presentation/pages/workspace/more/notes/editor/trip_note_link_field.dart (1)
  - features/trips/presentation/pages/workspace/overview/trip_overview_page.dart (1)
  - features/trips/presentation/pages/workspace/settings/information/trip_information_settings_page.dart (2)
  - features/trips/presentation/pages/workspace/settings/management/trip_management_settings_page.dart (1)
  - features/trips/presentation/pages/workspace/settings/privacy/trip_privacy_settings_page.dart (1)
  - features/trips/presentation/pages/workspace/settings/travellers/trip_traveller_profile_edit_page.dart (2)
  - features/trips/presentation/pages/workspace/settings/travellers/trip_travellers_settings_page.dart (3)
  - features/trips/sections/editor/trip_section_editor_frame.dart (1)
  - features/trips/sections/widgets/trip_section_expense_actions.dart (1)
  - features/trips/sections/widgets/trip_section_hours_sheet.dart (1)
  - features/trips/sections/widgets/trip_section_scaffold.dart (1)
  - features/trips/tools/audit/trip_audit_page.dart (1)
  - features/trips/tools/country_info/trip_country_info_page.dart (1)
  - features/trips/tools/search/trip_search_results.dart (1)
  - features/trips/tools/stats/trip_stats_page.dart (1)
  - features/trips/tools/weather/trip_weather_page.dart (1)

## COERENZA gruppo F - passo F1 (1.61.0)
Valutazione (regola 1): (a) la pagina Privacy usa frase introduttiva + AmaterasuSettingsCard espandibili; Aspetto aveva titoli e chip in fila; (b) Aspetto usa gli stessi componenti identici (card con icona, titolo e scelta attuale come descrizione; dentro le stesse scelte e le stesse chiavi), file diviso con un part; (c) nessun dato o calcolo: le scelte si salvano come prima. Card a tutta larghezza su schermo largo: nel codice delle Impostazioni non c'è nessun limite di larghezza; verificato con un test a 1400 punti (card oltre 1300). Test: impostazioni 17 (nuovi: frase, schermo largo, 130 % su telefono con tutte le card aperte).

## Mappa con i dati veri (1.62.0), prima della Coerenza F2
Valutazione (regola 1): (a) ogni sezione ha già la posizione (alloggi e bucket list: latitude/longitude; le altre: TripSectionPlace; trasporti: from e to) e uno store o repository di lettura; (b) lettura unica all'apertura con quegli store (alloggi con il loro repository, bucket list con la lettura a pagine estratta da Cerca in sections/data/trip_bucket_reader.dart, usata da Cerca e Mappa); nuovo modello TripMapPoint (gli elementi delle sezioni non hanno sempre un giorno), mappa, riquadro e gruppi riusati dalla bozza; (c) nessuna regola, funzione o API; alloggi e bucket list solo letti. Etichetta "Bozza" tolta dalla Mappa; l'Itinerario resta bozza fino al passo 2 (dati veri), dove si toglie l'implementazione demo.
- Trasporti: due punti (partenza e arrivo); annullati esclusi; elementi senza posizione contati ("N luoghi · M senza posizione").
- Filtro per giorno: gli elementi senza giorno restano visibili ma attenuati (decisione 8); linee tratteggiate per giorno in ordine di ora.
- Zone: città o area già salvate (nessun dato Google in più).

Prove da fare sul sito:
1. Altro > Mappa in un viaggio vero: compaiono alloggi, trasporti (due pin), prenotazioni, ristoranti, luoghi, bucket list; il contatore dice quanti non hanno posizione.
2. Filtro per giorno: i pin del giorno pieni, quelli senza giorno attenuati.
3. Tocco su un pin: "Apri la sezione" porta alla sezione giusta; "Apri su Maps" apre Google Maps.
4. Rotazione con due dita e "Nord in alto".

## Punto di ripresa (25/11/2026, dopo la 1.62.0)
Fatto: Mappa con i dati veri (1.62.0+71). Prossimo: ITINERARIO con i dati
veri, a passi come in docs/design/MAPPA-ITINERARIO.md (sezione 7) con le
11 decisioni (sezione 8), il principio fisso (sezione 9) e "Aggiungi
all'itinerario" (sezione 10):
1. Raccolta trips/{tripId}/itinerary: FirestoreTripItineraryRepository
   (stessa interfaccia TripItineraryRepository; togliere
   trip_itinerary_demo*.dart e l'etichetta "Bozza"); campi del documento
   (day, time, endTime, order, kind, ref, title, note, place con zona,
   actual {text?, ref?}, createdByUid, createdAt, updatedAt, updatedByUid);
   regole con sectionBase e firma; elimina solo autore o OWNER; test in
   rules-tests/sections/itinerary.test.mjs; raccolta in auditSections
   (functions/src/audit/audit-changes.ts) e nell'elenco delle sezioni
   dell'Audit Trail; "itinerary" in trip-duplication-policy (non copiato);
   deleteTrip la cancella già con le sottoraccolte; informativa: nessuna
   voce nuova di dati personali (stessi dati delle sezioni). Stato vuoto
   comune con invito ad aggiungere. Info del viaggio vere (giorni dal
   viaggio, nomi con tripStaysMemberNamesProvider, catalogo dagli elementi
   delle sezioni come la Mappa).
2. Giorno per giorno, zone, riordino solo delle voci senza ora, avvisi
   (sovrapposizioni con endTime quando c'è).
3. "Aggiungi nuovo" dall'itinerario: solo ristoranti e luoghi salvati.
4. Previsto/fatto (testo o elemento), condividi il giorno.
5. Vista mappa dell'itinerario; pulsante "Aggiungi all'itinerario" sulle
   card delle sezioni nuove (giorno e ora facoltativa).
Poi: COERENZA dal gruppo F (F2 dialoghi e username, F3 token, data/ora,
130 %), E, D, B, C con la home, A per ultimo.
