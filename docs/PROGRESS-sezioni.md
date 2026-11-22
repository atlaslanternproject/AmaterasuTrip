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
| 1. Hotel e alloggi, migliorie | fatta (pubblicazione: vedi sotto) | feature/alloggi-migliorie | 1.15.0+19 |
| 2. Trasporti | da fare | - | - |
| 3. Prenotazioni | da fare | - | - |
| 4. Ristoranti | da fare | - | - |
| 5. Luoghi salvati | da fare | - | - |
| 6. Note | da fare | - | - |
| 7. Shopping e valigia | da fare | - | - |
| 8. Ricordi | da fare | - | - |
| 9. Spese, esportazione CSV/PDF | da fare | - | - |
| 10. Analisi Drive e budget per categoria | da fare | - | - |

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
