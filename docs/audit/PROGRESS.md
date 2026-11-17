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

Escluso dallo script: `functions/test/macro3b-client-wiring.test.cjs`
(5 test su 5 falliscono già su main: controlla la cifratura E2EE rimossa).

## Passi

| Passo | Stato | Commit |
|---|---|---|
| Fase 0 - base e script dei controlli | fatto | (questo) |
| Fase 1 - report docs/audit/AUDIT.md | in corso | |
| Fase 2 - correzioni | in attesa del "procedi" | |

## Prossimo passo
Scrivere docs/audit/AUDIT.md (sola lettura), poi fermarsi.
