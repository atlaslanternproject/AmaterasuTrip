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
| 1. Hotel e alloggi, migliorie | da fare | - | - |
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
