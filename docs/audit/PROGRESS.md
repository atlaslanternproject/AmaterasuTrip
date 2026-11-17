# Audit di manutenibilità - avanzamento

Branch: `chore/audit-manutenibilita` (partito da `main` @ `ebf008b`).
Nessun push, merge o deploy.

Controlli: `bash tool/check_all.sh` (Git Bash, dalla cartella principale).

## Base di partenza (Fase 0, 2026-11-17)

| Controllo | Risultato |
|---|---|
| flutter analyze | 0 avvisi ("No issues found") |
| flutter test | 384 test passati, 0 falliti |
| controllo traduzioni (tool/check_l10n.dart) | OK |
| functions: lint (eslint) | 0 errori |
| functions: build (tsc) | OK |
| test node | 38 passati (parity 13, history 6, account-deletion 7+4+8) |
| emulatore: regole budget | PASSED |
| emulatore: privacy budget | PASSED (24 verifiche) |
| emulatore: integrazione budget | PASSED (55 verifiche) |

`functions/test/macro3b-client-wiring.test.cjs` falliva già su main
(controllava la cifratura E2EE rimossa): eliminato nel passo a2.

## Passi

| Passo | Stato | Commit | Note |
|---|---|---|---|
| Fase 0 - base e script dei controlli | fatto | 890c305 | |
| Fase 1 - report AUDIT.md | fatto | 81d5f7e | |
| a1 - fine riga, .gitignore, node_modules, import minuscoli | fatto | dbaeed3 | B1, B2, B3, B4, B11 |
| a2 - codice morto, test obsoleti, configurazioni vecchie | fatto | 4f90d19 | C1 (parte sicura), C2, C5, S2/B5. Test Flutter 384 → 381 (tolti 3 test del codice permessi eliminato) |
| a3 - log con email/UID solo in debug | fatto | 316fe08 | S5 |
| B8 - archivio fuori dal progetto | fatto | (nessun commit: file ignorati da git) | APK, backup B8.4-B8.7, build web vecchia e log spostati in `../AmaterasuTrip-archivio` |
| b - colori e stile | da fare | | |
| c - localizzazioni | da fare | | |
| d - struttura | da fare | | |
| e - intestazioni e TODO(audit) | da fare | | |
| f - dipendenze (con C11) | da fare | | |
| g - README, CLAUDE.md, B10 | da fare | | |

## Prossimo passo
Passo b: nuovi token colore con gli stessi valori e sostituzione dei
colori scritti a mano.
