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
| 0. Modulo Luogo condiviso (lib/core/places) | in corso | feature/luogo-condiviso | - |
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
- docs: CLAUDE.md e questo file.
