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
| Extra E2 - Pagina Impostazioni > Aspetto | fatta (pubblicazione: vedi tappa seguente) | feature/aspetto-e2 | 1.42.0+47 |
| Extra F-H | da fare | - | - |
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
