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
| b1 - token colore | fatto | 23d19cc | ST1, ST2: 41 token, 495 colori in 94 file |
| b2 - token spaziatura e raggio | fatto | 0d26c24 | ST3 parziale: 220 spaziature e 23 raggi con i token esistenti, solo valori identici |
| c1 - l10n.yaml e chiavi non usate | fatto | 8e90506 | B9, L2: 186 chiavi tolte (1083 → 897 per lingua) |
| c2 - doppioni del budget | fatto | f2ced17 | L3 solo area budget: 59 chiavi unite in 23 (897 → 861). Aree account/trip non toccate (funzioni approvate) |
| d1 - budgetL10n condiviso | fatto | 67caa4e | C6 (13 copie). C8 non fatta: le tre _money gestiscono gli errori in modo diverso |
| d2 - requireVerifiedUid condiviso | fatto | 6ed7ce8 | C13 (15 copie). C14 non era un doppione: i due validId fanno controlli diversi |
| d3-d15 - divisione file Dart grandi (part) | fatto | bc8c4e1 … c216fcd | 13 file, un commit ciascuno. Restano sopra 200 righe dove c'è un build lungo (vedi AUDIT) |
| d16 - functions/src/index.ts in moduli | fatto | 2631bb2 | 849 → 73 righe; stesse 30 funzioni esportate; test emulatore removeTripMember 5/5 |
| d17 - budget-validation, budget-fx, duplicate-trip | fatto | dc3d9d4 | 172, 135, 200 righe |
| e - intestazioni e TODO(audit) | fatto | 1cd858b | 360 file Dart (lib, test, tool) con intestazione; 39 TODO(audit) (38 Dart, 1 TypeScript) |
| f1 - pacchetti non usati | fatto | 3011765 | C11: 9 pacchetti tolti; cupertino_icons tenuto (la build web segnala icone del framework che lo usano). flutter build web e build apk --debug OK |
| f2 - Flutter minor/patch | fatto | 36fb040 | 36 pacchetti aggiornati nei limiti di pubspec.yaml; build web e apk OK. Un primo giro dei controlli è fallito solo perché i file l10n erano in rigenerazione: ripetuto, tutto OK |
| f3 - functions npm | fatto | 8963487 | S3: produzione critica 1 → 0, alte 2 → 0, moderate 9 → 8 (restano solo con firebase-admin 14) |
| f4 - rules-tests npm | fatto | 51da218 | S4: alte 6 → 5 (le altre richiedono versioni maggiori); test regole 21/21 + B7.1 + B7.5.2 OK prima e dopo |
| g - README, CLAUDE.md, B10 | da fare | | |

## Prossimo passo
Passo g: README vero, CLAUDE.md aggiornato (convenzioni, niente QR),
titolo e descrizione in web/index.html (B10), descrizione in pubspec.yaml (D3).
