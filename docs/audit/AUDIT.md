# Audit di manutenibilità - Amaterasu Trip

Data: 2026-11-17 · Branch: `chore/audit-manutenibilita` (da `main` @ `ebf008b`)
Report in sola lettura: nessun file del progetto è stato modificato per scriverlo.

**Impatto sulla funzionalità**
- **nessuno**: l'app funziona e appare esattamente come ora; i controlli automatici lo verificano.
- **da verificare**: non dovrebbe cambiare nulla, ma serve una prova sull'app o una verifica fuori dal codice.
- **da decidere io**: cambia qualcosa di visibile, tocca aree vietate da questo audit (regole, hosting, dati salvati, versioni maggiori) o funzioni approvate, oppure richiede una scelta.

Base di partenza (Fase 0): analisi 0 avvisi · 384 test Flutter · controllo traduzioni OK · lint e build functions OK · 38 test node · 3 test emulatore budget OK. Dettagli in [PROGRESS.md](PROGRESS.md).

## Avanzamento delle correzioni

| Voce | Stato | Commit |
|---|---|---|
| B1 import minuscoli | risolta | dbaeed3 |
| B2 fine riga (.gitattributes) | risolta | dbaeed3 |
| B3 rules-tests/node_modules fuori da git | risolta | dbaeed3 |
| B4 .gitignore | risolta | dbaeed3 |
| B11 cartella vuota notifications | risolta | dbaeed3 (cartella non tracciata, cancellata) |
| C1 file morti sicuri (probe E2EE, external_locale, budget_overview, bucket_vote, roster provider) | risolta | 4f90d19 |
| C1 TripWorkspaceHeader/Card, browser cartelle Drive | non toccata (non autorizzata) | — |
| C2 resti notifiche e permessi (+ test relativo) | risolta | 4f90d19 |
| C5 test macro3b | risolta | 4f90d19 |
| S2/B5 configurazioni bucket-list vecchie | risolta (nessuno script o test le usava) | 4f90d19 |
| S5 log con email/UID solo in debug | risolta (40 righe) | 316fe08 |
| B8 APK, backup e log spostati in `../AmaterasuTrip-archivio` | risolta (file ignorati da git, nessun commit). `desktop.ini` lasciato: è il file di Windows per l'icona della cartella | — |
| ST1, ST2 colori come token (41 token, 495 sostituzioni; i colori usati 1-2 volte restano nei file) | risolta | 23d19cc |
| ST3 spaziature e raggi con i token esistenti (220 + 23, solo valori identici: 4/8/16/24/32/48 e 8/14/24) | risolta in parte: i valori senza token (10, 12, 17, 18…) restano numeri | 0d26c24 |
| B9 l10n.yaml (file generati identici, verificato) | risolta | 8e90506 |
| L2 chiavi non usate (186: il conteggio sale da 178 dopo le eliminazioni del passo a) | risolta | 8e90506 |
| L3 doppioni nella stessa area | risolta solo per il budget (59 chiavi → 23). Doppioni di account e trip lasciati: sono funzioni approvate | f2ced17 |
| Nota L-conteggi | Le chiavi erano 1.083 per lingua (il numero 1.143 del report contava anche i nomi dei segnaposto) | — |
| C6 _l10n condiviso (budget_l10n.dart) | risolta | 67caa4e |
| C8 _money | non fatta: le tre versioni gestiscono gli errori in modo diverso (nessuna gestione / qualsiasi errore / solo ArgumentError); unirle cambierebbe la logica | — |
| C13 requireVerifiedUid | risolta | 6ed7ce8 |
| C14 validId | non era un doppione: quello del budget lancia un errore con un formato UID, quello della bucket list restituisce vero/falso con regole diverse | — |
| 3.1 file grandi non approvati | risolti 17 su 20 (dettaglio sotto) | bc8c4e1 … dc3d9d4 |

Dettaglio divisione (righe prima → dopo, file principale). Metodo: i metodi della classe State sono stati spostati identici in file `part` come `extension` (stesso schema della bucket list); le classi di primo livello spostate in `part`; nelle functions moduli separati riesportati con gli stessi nomi. Verificato per ogni file che le righe di codice siano le stesse.

| File | Prima | Dopo | Nota |
|---|---|---|---|
| budget_create_dialog.dart | 840 | 489 | resta `build` di 415 righe |
| budget_reimbursements_panel.dart | 827 | 453 | resta `build` di 394 righe |
| personal_trip_budget_card.dart | 671 | 292 | resta `build` di 213 righe |
| budget_category_dashboard.dart | 670 | 185 | la parte `_summary` è un metodo unico di 321 righe |
| budget_user_settlement_summary.dart | 624 | 511 | resta `build` di 421 righe |
| budget_revision_panel.dart | 548 | 220 | la parte `_edit` è un metodo unico di 252 righe |
| budget_api.dart | 455 | 455 | non diviso: i test ne fanno una versione finta che sovrascrive i metodi, impossibile con le extension |
| budget_expense_details_dialog.dart | 339 | 226 | resta `build` di 192 righe |
| budget_history_view.dart | 331 | 143 | |
| budget_expense_list.dart | 305 | 256 | resta `build` di 222 righe |
| budget_expenses_toolbar.dart | 296 | 294 | non diviso: è quasi tutto un unico `build` |
| budget_charts.dart | 294 | 101 | |
| trip_expenses_page.dart | 378 | 240 | resta `build` di 180 righe |
| router.dart | 546 | 546 | non diviso: è un'unica espressione GoRouter; dividerla vuol dire riorganizzare le rotte |
| trip_overview_page.dart | 545 | 137 | |
| login_card.dart | 277 | 228 | resta `build` di 183 righe |
| functions/src/index.ts | 849 | 73 | 9 funzioni in src/trip-invites e src/trip-members |
| functions/src/trip-management/duplicate-trip.ts | 297 | 200 | |
| functions/src/budget/budget-fx.ts | 258 | 135 | |
| functions/src/budget/budget-validation.ts | 255 | 172 | |

Per scendere sotto le 200 righe nei file con un `build` lungo bisogna estrarre pezzi di interfaccia in widget: è una riorganizzazione del codice (stesso aspetto, ma struttura diversa) che va decisa e provata a parte. Segnata con TODO(audit) nel passo e.

---

## 1. Sicurezza

| ID | File / riga | Problema | Rischio | Correzione proposta | Impatto |
|---|---|---|---|---|---|
| S1 | (console Firebase) | L'app usa Firebase Storage (`lib/features/profile/data/services/profile_photo_storage_service.dart`), ma nel progetto non c'è un file di regole Storage e `firebase.json` non lo cita. Le regole esistono solo nella console. | Alto: non si possono leggere, testare né ripristinare. Un errore fatto in console non lascia traccia. | Scaricare le regole attuali dalla console in `storage.rules`, aggiungerle a `firebase.json` e scrivere test emulatore. | da decidere io (tocca regole e firebase.json) |
| S2 | `firebase.bucket-list.deploy.json:21` + `firestore.bucket-list.candidate.rules` | Configurazione alternativa che pubblica le regole "candidate" di ottobre (diverse dalle attuali: ammettono ancora `fcmToken`, ecc.) e un hosting da `.bucket_list_release_web`. | Alto se usata per errore con `firebase deploy --config`: sovrascrive regole e sito con versioni vecchie. | Eliminare i due file (e `firebase.bucket-list.release.json`, vedi B5). | da decidere io (riguarda regole e hosting) |
| S3 | `functions/package-lock.json` | `npm audit` (solo dipendenze di produzione): 13 vulnerabilità, di cui 1 critica (`proxy-addr`), 2 alte (`@grpc/grpc-js`, `body-parser`). Tutte indirette. | Medio: le Cloud Functions girano sul server. | `npm audit fix` senza `--force` corregge quelle senza salto di versione maggiore (proxy-addr, grpc-js, body-parser, qs, gaxios, fast-xml-parser). Le altre richiedono `firebase-admin` 14 (maggiore). | nessuno per la parte minor/patch (passo f); da decidere io per firebase-admin 14 |
| S4 | `rules-tests/package-lock.json` | 6 vulnerabilità alte (firebase, grpc-js, re2js…). | Basso: solo strumenti di test locali. | `npm audit fix` dove non serve una versione maggiore. | nessuno (passo f) |
| S5 | `lib/features/settings/data/services/account_deletion_service.dart:55-56, 346-347`; `lib/features/auth/presentation/pages/auth_gate.dart:38, 47`; `lib/features/auth/presentation/pages/google_auth.dart:45-46`; `lib/features/auth/presentation/widgets/login_card.dart:60`; `create_username_page.dart:72, 81` | `debugPrint` stampa email e UID. In totale 272 `debugPrint` in `lib/`. `debugPrint` funziona anche nella versione pubblicata: su Android finisce nel log di sistema. | Basso-medio: dati personali leggibili nei log del telefono. | Togliere o proteggere con `kDebugMode` i messaggi con dati personali. | da verificare (nessun effetto visibile, ma tocca auth e impostazioni approvate). Nel passo e) metto solo `TODO(audit)` |
| S6 | `lib/firebase_options.dart`, `android/app/google-services.json` | Chiavi API Firebase nel repository. È normale (sono pubbliche per progetto), ma vanno limitate. | Basso se le chiavi sono limitate in Google Cloud. | Controllare in Google Cloud Console che ogni chiave sia limitata per app (Android: firma SHA; Web: dominio). | da verificare (fuori dal codice) |
| S7 | `.env.local.json`, `build/web/main.dart.js` | La chiave Google Maps Web NON è mai entrata nella cronologia git (verificato). Viene però inserita nel JavaScript pubblicato, inevitabile per Maps Web. | Basso se limitata per dominio. | Verificare la limitazione per dominio (HTTP referrer) e per API in Google Cloud. | da verificare (fuori dal codice) |
| S8 | `lib/main.dart:22` | Chiave finta `AIzaSy000…` per il progetto di test `demo-amaterasu-security`. | Nessuno: è un valore fittizio usato solo con gli emulatori. | Nessuna. | — (solo informativo) |
| S9 | cronologia git | Nessun file `.env`, chiave privata, keystore o account di servizio è mai stato committato (verificato su tutta la cronologia). `android/key.properties` e `android/upload-keystore.jks` sono correttamente ignorati. | — | Tenere una copia del keystore fuori dalla cartella del progetto. | — (solo informativo) |
| S10 | `firestore.rules` | Regole ben fatte: accesso negato di base (`match /{document=**}` riga 584), scritture del budget solo dal server, campi ammessi elencati. Osservazioni: `e2eeRoots` (riga 577) è un blocco della vecchia E2EE ormai inutile; `viaggiatori` permette la cancellazione del proprio profilo (riga 122) lasciando il documento in `usernames`. | Basso. | Togliere il blocco `e2eeRoots` (non cambia nulla: è già tutto negato); valutare se la cancellazione del profilo debba passare dal server. | da decidere io (regole Firestore) |
| S11 | `android/app/src/main/AndroidManifest.xml:2` | Permesso `CAMERA` dichiarato. Serviva anche allo scanner QR, che oggi non è più usato (vedi C11). Resta usato da `image_picker` per scattare la foto. | Basso. | Tenerlo finché la foto da fotocamera esiste. | — (solo informativo) |
| S12 | `android/app/src/localtestDebug/AndroidManifest.xml:2` | `usesCleartextTraffic="true"` solo nella variante di test locale (serve per gli emulatori). | Nessuno per l'app pubblicata. | Nessuna. | — (solo informativo) |
| S13 | `web/index.html` | Nessuna intestazione di sicurezza (Content-Security-Policy). | Basso. | Valutare intestazioni in `firebase.json` (hosting). | da decidere io (hosting) |

## 2. Build e portabilità

| ID | File / riga | Problema | Rischio | Correzione proposta | Impatto |
|---|---|---|---|---|---|
| B1 | 15 file, 36 import (elenco sotto) | Import con la "A" maiuscola (`Amaterasu_colors.dart`, `Amaterasu_primary_button.dart`, …) mentre i file veri sono tutti minuscoli. I file NON vanno rinominati: basta correggere il testo dell'import. | Alto su macOS/Linux/CI: la compilazione fallisce. Anche su Windows lo stesso file può essere caricato due volte con nomi diversi. | Correggere le 36 righe. | nessuno (passo a) |
| B2 | `macos/Flutter/GeneratedPluginRegistrant.swift`, `windows/flutter/generated_plugins.cmake` | Risultano sempre "modificati" ma il contenuto è identico. Causa: `core.autocrlf=true` e nessun `.gitattributes`; il repository salva tutto in LF (531 file su 531). | Basso: rumore continuo in `git status`, commit accidentali. | Aggiungere `.gitattributes` con `* text=auto eol=lf` (più `*.bat`/`*.cmd eol=crlf`) e normalizzare. | nessuno (passo a) |
| B3 | `rules-tests/node_modules/` | **9.451 file di `node_modules` sono dentro git** (su 10.032 file totali). | Medio: repository enorme, aggiornamenti dei pacchetti illeggibili nei diff, vulnerabilità committate. | `git rm -r --cached rules-tests/node_modules` (i file restano sul disco) e regola `node_modules/` nel `.gitignore` principale. | nessuno (passo a) |
| B4 | `.gitignore:64` e `:66` | `.bucket_list_release_web/` ripetuto due volte. Manca una regola generale per `node_modules/`. | Basso. | Togliere il doppione, aggiungere `node_modules/`. | nessuno (passo a) |
| B5 | `firebase.bucket-list.release.json` | Copia della configurazione hosting che pubblica `.bucket_list_release_web` (una build web di ottobre). Non è usata da nessuno script. | Medio: deploy di una versione vecchia del sito se usata per errore. | Eliminarla (vedi anche S2). | da decidere io (hosting) |
| B6 | `firebase.emulators.security-test.json` | Usata dai test emulatore (porte 18080/19099/15001). | — | Tenerla. È documentata in `tool/check_all.sh`. | — |
| B7 | `firebase.json` | La sezione `emulators` ha solo `auth` (porta 9099). La sezione hosting pubblica `build/web`, ma le pagine di `hosting/` (invito, cancellazione account) vanno copiate a mano in `build/web` prima del deploy: nessuno script lo fa. | Medio: dimenticare la copia pubblica un sito senza la pagina invito. | Documentare il passaggio nel README; in futuro uno script di build. | nessuno per la documentazione (passo g); da decidere io per lo script |
| B8 | file nella cartella del progetto (ignorati da git) | `amaterasu-installed.apk` (114 MB), `.local-backup-B84-B87/` (41 MB, contiene `checkpoint.zip`), `.bucket_list_release_web/` (46 MB), `firestore-debug.log`, `functions/firestore-debug.log`, `desktop.ini`. | Basso: spazio e confusione. Non entrano in git. | Spostarli fuori dal progetto o cancellarli. | da decidere io (sono copie tue: non le cancello senza conferma) |
| B9 | (assente) `l10n.yaml` | `pubspec.yaml` ha `generate: true` ma non c'è `l10n.yaml`: la generazione dei file di traduzione usa i valori predefiniti di Flutter (modello `app_en.arb`), mentre `tool/check_l10n.dart` usa l'italiano come riferimento. | Basso: un aggiornamento di Flutter può cambiare il risultato. | Aggiungere `l10n.yaml` con le impostazioni che producono gli stessi file di oggi (lo verifico rigenerando e confrontando). | nessuno (passo c, solo se i file rigenerati sono identici) |
| B10 | `web/index.html:21, 32` | Descrizione "A new Flutter project." e titolo della scheda "amaterasutrip". | Basso. | Titolo "Amaterasu Trip" e descrizione vera. | da decidere io (il titolo della scheda è visibile) |
| B11 | `functions/src/notifications/` | Cartella vuota (non è in git), resto della rimozione delle notifiche. | Nessuno. | Cancellarla. | nessuno (passo a) |

Elenco B1 (file → import sbagliati): `lib/core/theme/app_theme.dart` (1), `lib/core/widgets/auth/amaterasu_email_verification_card.dart` (1), `lib/core/widgets/buttons/amaterasu_discord_button.dart` (1), `amaterasu_google_button.dart` (1), `amaterasu_primary_button.dart` (2), `lib/core/widgets/cards/amaterasu_card.dart` (3), `lib/core/widgets/common/amaterasu_divider.dart` (1), `lib/core/widgets/inputs/amaterasu_password_field.dart` (2), `amaterasu_text_field.dart` (2), `lib/core/widgets/layout/amaterasu_background.dart` (1), `lib/features/auth/presentation/pages/auth_page.dart` (2), `register_page.dart` (2), `verify_email_page.dart` (2), `lib/features/auth/presentation/widgets/login_card.dart` (7), `register_card.dart` (7), `lib/features/settings/presentation/pages/account/account_password_page.dart` (1).

## 3. Codice

### 3.1 File con più di 250 righe

48 file scritti da noi (44 Dart + 4 TypeScript). Esclusi i 3 file generati di `lib/l10n/` (6.627 + 3.347 + 3.347 righe). "Area" indica se il file appartiene a una funzione approvata.

| Righe | File | Area | Impatto della divisione |
|---|---|---|---|
| 1224 | lib/features/trips/presentation/pages/workspace/settings/travellers/trip_travellers_settings_page.dart | gestione viaggio (approvata) | da decidere io |
| 1064 | lib/features/trips/presentation/pages/workspace/settings/information/trip_information_settings_page.dart | gestione viaggio (approvata) | da decidere io |
| 974 | lib/features/trips/presentation/pages/workspace/settings/management/trip_management_settings_page.dart | gestione viaggio (approvata) | da decidere io |
| 937 | lib/features/trips/presentation/pages/workspace/bucket_list/bucket_activity_editor_part.dart | bucket list (approvata) | da decidere io |
| 849 | functions/src/index.ts | inviti e viaggiatori | nessuno |
| 840 | lib/features/trips/budget/presentation/budget_create_dialog.dart | budget | nessuno |
| 827 | lib/features/trips/budget/presentation/budget_reimbursements_panel.dart | budget | nessuno |
| 671 | lib/features/trips/budget/presentation/personal_trip_budget_card.dart | budget | nessuno |
| 670 | lib/features/trips/budget/presentation/budget_category_dashboard.dart | budget | nessuno |
| 643 | lib/features/trips/presentation/pages/create_trip/create_trip_page.dart | gestione viaggio (approvata) | da decidere io |
| 624 | lib/features/trips/budget/presentation/budget_user_settlement_summary.dart | budget | nessuno |
| 597 | lib/features/trips/presentation/pages/workspace/bucket_list/bucket_method_page_view.dart | bucket list (approvata) | da decidere io |
| 597 | lib/features/settings/presentation/pages/profile/profile_page.dart | impostazioni (approvata) | da decidere io |
| 592 | lib/features/trips/presentation/pages/create_trip/cloud_archive/google_drive_folder_browser_page.dart | non usato (C1) | — |
| 583 | lib/features/trips/data/services/google_drive_archive_service.dart | gestione viaggio (approvata) | da decidere io |
| 548 | lib/features/trips/budget/presentation/budget_revision_panel.dart | budget | nessuno |
| 546 | lib/app/router.dart | struttura app | nessuno |
| 545 | lib/features/trips/presentation/pages/workspace/overview/trip_overview_page.dart | panoramica | nessuno |
| 495 | lib/features/trips/presentation/pages/create_trip/destination/widgets/destination_world_map.dart | gestione viaggio (approvata) | da decidere io |
| 486 | lib/features/trips/presentation/pages/create_trip/cloud_archive/trip_cloud_archive_page.dart | gestione viaggio (approvata) | da decidere io |
| 482 | lib/features/trips/presentation/pages/create_trip/destination/trip_destination_page.dart | gestione viaggio (approvata) | da decidere io |
| 481 | lib/features/settings/data/services/account_deletion_service.dart | impostazioni (approvata) | da decidere io |
| 468 | lib/features/settings/presentation/pages/account/account_password_page.dart | impostazioni (approvata) | da decidere io |
| 455 | lib/features/trips/budget/presentation/budget_api.dart | budget | nessuno |
| 451 | lib/features/trips/presentation/pages/create_trip/trip_created_page.dart | gestione viaggio (approvata) | da decidere io |
| 422 | lib/features/trips/presentation/pages/workspace/settings/travellers/trip_traveller_profile_edit_page.dart | gestione viaggio (approvata) | da decidere io |
| 403 | lib/features/trips/presentation/pages/workspace/settings/privacy/trip_privacy_settings_page.dart | gestione viaggio (approvata) | da decidere io |
| 398 | lib/features/trips/presentation/pages/workspace/bucket_list/bucket_activity_card_part.dart | bucket list (approvata) | da decidere io |
| 389 | lib/features/trips/presentation/widgets/trip_card.dart | gestione viaggio (approvata) | da decidere io |
| 378 | lib/features/trips/presentation/pages/workspace/expenses/trip_expenses_page.dart | budget | nessuno |
| 363 | lib/features/settings/presentation/pages/account/account_email_actions.dart | impostazioni (approvata) | da decidere io |
| 354 | lib/features/trips/presentation/pages/trips_page.dart | gestione viaggio (approvata) | da decidere io |
| 339 | lib/features/trips/budget/presentation/budget_expense_details_dialog.dart | budget | nessuno |
| 331 | lib/features/trips/budget/presentation/budget_history_view.dart | budget | nessuno |
| 310 | lib/features/trips/presentation/pages/workspace/bucket_list/bucket_deletion_review_part.dart | bucket list (approvata) | da decidere io |
| 305 | lib/features/trips/budget/presentation/budget_expense_list.dart | budget | nessuno |
| 297 | functions/src/trip-management/duplicate-trip.ts | gestione viaggio (server) | nessuno |
| 296 | lib/features/trips/budget/presentation/budget_expenses_toolbar.dart | budget | nessuno |
| 294 | lib/features/trips/budget/presentation/budget_charts.dart | budget | nessuno |
| 284 | lib/features/trips/data/repositories/trip_repository.dart | gestione viaggio (approvata) | da decidere io |
| 277 | lib/features/auth/presentation/widgets/login_card.dart | accesso | nessuno |
| 274 | lib/features/trips/presentation/pages/invite/trip_invite_page.dart | gestione viaggio (approvata) | da decidere io |
| 266 | lib/features/settings/presentation/pages/account/account_delete_dialog.dart | impostazioni (approvata) | da decidere io |
| 258 | lib/features/trips/bucket_list/data/bucket_deletion_repository.dart | bucket list (approvata) | da decidere io |
| 258 | functions/src/budget/budget-fx.ts | budget (server) | nessuno |
| 255 | functions/src/budget/budget-validation.ts | budget (server) | nessuno |
| 252 | lib/b10_persistence_probe.dart | non usato (C1) | — |
| 251 | lib/features/settings/presentation/pages/data/data_sync_settings_page.dart | impostazioni (approvata) | da decidere io |

Riepilogo: 20 file dividibili con impatto **nessuno** (budget, router, panoramica, login, 4 file TypeScript); 26 in funzioni approvate (**da decidere io**); 2 da eliminare (C1).

### 3.2 Altri problemi del codice

| ID | File / riga | Problema | Rischio | Correzione proposta | Impatto |
|---|---|---|---|---|---|
| C1 | `lib/b10_persistence_probe.dart` (252 righe), `lib/features/trips/presentation/pages/create_trip/cloud_archive/google_drive_folder_browser_page.dart` (592), `lib/features/trips/budget/presentation/budget_overview.dart` (163), `lib/features/trips/presentation/pages/workspace/widgets/trip_workspace_header.dart` (128), `trip_workspace_card.dart` (88), `lib/core/localization/external_locale.dart` (19), `lib/features/trips/bucket_list/models/bucket_vote.dart` (11), `lib/features/trips/bucket_list/providers/bucket_voting_roster_provider.dart` (24) | File mai importati dall'app né dai test (verificato seguendo gli import da `lib/main.dart` e cercando i nomi delle classi). `b10_persistence_probe.dart` è un programma di prova della vecchia E2EE con un suo `main()`. | Basso: confondono chi legge (CLAUDE.md cita TripWorkspaceHeader e TripWorkspaceCard come componenti da riusare, ma nessuno li usa). | Eliminare. Per header/card e la cartella Drive valuta se tenerli per il futuro. | nessuno per probe, external_locale, budget_overview, bucket_vote, roster provider; da decidere io per header/card del workspace e il browser cartelle Drive (approvata) |
| C2 | `lib/core/permissions/` (8 file), `lib/features/settings/providers/notification_permission_provider.dart`, `lib/features/trips/data/models/trip_notification_preferences.dart`, `lib/features/trips/data/repositories/trip_notification_preferences_repository.dart` | Resti del sistema notifiche rimosso a ottobre: non raggiunti dall'app (3 file di `permissions` sono usati solo da un test). | Basso. | Eliminare insieme ai test che li riguardano. | da decidere io (bisogna eliminare anche un test, e il patto è di non toccare i test) |
| C3 | `lib/features/trips/budget/calculations/` (10 file), `models/` (11), `policies/` (2), `services/expense_revision_service.dart`, `data/codecs/` (3), `data/paths/budget_firestore_paths.dart` | Usati solo dai test, non dall'app: sono la copia Dart dei calcoli del server, usata per i test di parità con le Cloud Functions. | Basso, ma vanno tenuti allineati a mano. | Tenerli; spiegarlo nell'intestazione dei file (passo e). | nessuno |
| C4 | `functions/src/account-deletion/` (`account-deletion-cleanup-orchestrator.ts`, `account-deletion-preflight.ts`, `firestore-account-deletion-cleanup-port.ts`) e `functions/src/index.ts:820` | La pulizia lato server della cancellazione account è scritta e testata ma non collegata a nessuna funzione. `inspectAccountDeletionTrips` è esportata ma l'app non la chiama mai (l'app cancella i dati direttamente dal client). | Medio: funzione pubblicata inutilmente; lavoro a metà. | Decidere se completare la cancellazione lato server o togliere la funzione. | da decidere io (nome di funzione chiamabile) |
| C5 | `functions/test/macro3b-client-wiring.test.cjs` | 5 test su 5 falliscono già su main: cercano la vecchia cifratura E2EE (`acceptTripInviteEncrypted`). Escluso da `tool/check_all.sh`. | Basso: test che non protegge più nulla. | Eliminarlo. | da decidere io (è un test) |
| C6 | 14 file del budget (es. `budget_create_dialog.dart:840`, `budget_reimbursements_panel.dart:827`, `trip_expenses_page.dart:378`) | Stessa funzione `_l10n(bool it) => lookupAppLocalizations(Locale(it ? 'it' : 'en'))` copiata 14 volte. | Basso. | Modulo condiviso `lib/features/trips/budget/presentation/budget_l10n.dart`. | nessuno (passo d) |
| C7 | `budget_create_dialog.dart:81`, `budget_expenses_toolbar.dart:25`, `personal_trip_budget_card.dart:97` | Tre versioni simili della scelta valuta (`_pickCurrency`). | Basso. | Un solo dialogo condiviso, se il risultato è identico. | da verificare (piccole differenze di aspetto da confrontare) |
| C8 | `budget_category_dashboard.dart:79`, `budget_display_amount.dart:90`, `budget_history_view.dart:209` | `_money(...)` ripetuto attorno a `BudgetMoneyFormatter.format`, con gestione degli errori diversa. | Basso. | Un helper condiviso con la stessa gestione degli errori di oggi per ciascun uso. | nessuno (passo d) |
| C9 | `account_password_page.dart:122, 302`, `create_trip_page.dart:393`, `trip_information_settings_page.dart:950`, `trip_management_settings_page.dart:51`, `trip_travellers_settings_page.dart:399` | `_showMessage` (SnackBar) ripetuto in 6 punti. | Basso. | Funzione condivisa in `lib/core/widgets/`. | da decidere io (tutti in funzioni approvate) |
| C10 | `trip_cover_picker.dart`, `trip_overview_page.dart`, `trip_card.dart` (`_TripCoverFallback`); 3 pagine di impostazioni viaggio (`_Header`), 2 (`_SectionTitle`, `_CenteredMessage`) | Widget privati con lo stesso nome e codice simile ma non identico. | Basso. | Unificare solo dove l'aspetto resta identico. | da decidere io (approvate; piccole differenze visive) |
| C11 | `pubspec.yaml` | Pacchetti mai importati: `qr_flutter`, `mobile_scanner`, `country_picker`, `web`, `googleapis_auth`, `extension_google_sign_in_as_googleapis_auth`, `cupertino_icons`. `cryptography` e `flutter_secure_storage` usati solo dal file morto `b10_persistence_probe.dart`; `permission_handler` solo da file morti (C2). | Medio: app più pesante, più permessi e codice nativo, più aggiornamenti. CLAUDE.md dice "Profilo utente con QR", ma il QR non è più nel codice dal commit `1faa271`. | Rimuoverli dopo aver tolto i file morti; poi provare build Android e Web. | da verificare (togliere plugin nativi cambia i file generati e il manifest Android) |
| C12 | `pubspec.yaml`, `functions/package.json` | Pacchetti vecchi: aggiornamenti minor/patch disponibili per cloud_firestore 6.10.2, cloud_functions 6.5.1, firebase_auth 6.7.1, firebase_core 4.15.2, firebase_storage 13.6.1, flutter_riverpod 3.5.0, googleapis_auth 2.3.7, image_picker 1.2.4, package_info_plus 10.2.2, shared_preferences 2.5.6, url_launcher 6.3.3; firebase-functions 7.4.0, @typescript-eslint 8.73.0. Versioni maggiori disponibili (non da fare ora): cloud_firestore 7, firebase_auth 7, firebase_core 5, firebase_storage 14, go_router 18, google_sign_in 7, googleapis 19, firebase_app_check 0.5, firebase-admin 14, eslint 10, typescript 7. | Medio nel tempo. | Passo f: solo minor/patch, con i controlli. | nessuno (minor/patch); da decidere io (maggiori) |
| C13 | `functions/src/budget/*.ts` (15 punti) | Il controllo "utente con email verificata" (`request.auth?.uid` + `email_verified`) è copiato 15 volte; `const db = getFirestore()` in ogni file. | Basso. | Helper `requireVerifiedUid(request)` in `functions/src/shared/`. | nessuno (passo d) |
| C14 | `functions/src/bucket-list/approve-bucket-activity-deletion.ts:18` | `validId` riscritto uguale a quello di `budget/budget-validation.ts`. | Basso. | Spostare in `functions/src/shared/`. | nessuno (passo d) |
| C15 | `functions/scripts/budget-backfill-participants.cjs` | Script di migrazione da eseguire una sola volta, con credenziali reali. | Basso (parte in prova, serve `--apply`). | Tenerlo, segnalarlo nel README. | nessuno |

## 4. Stile

Valori dei token di oggi (`AmaterasuColors`): nessuno dei 7 colori del tema compare scritto a mano nelle schermate. Le schermate usano un'altra tavolozza (crema, bruni, arancio). Per questo **non si può "sostituire con i token esistenti"**: servono **nuovi token con lo stesso valore esatto**, così l'aspetto non cambia.

| ID | File / riga | Problema | Rischio | Correzione proposta | Impatto |
|---|---|---|---|---|---|
| ST1 | 97 file, 669 `Color(0x…)` | Colori scritti a mano: 180 valori diversi. I più usati: `F2E7D5` ×91, `B7A99B` ×64, `100C0A` ×36, `E28A32` ×25, `1A1512` ×23, `3A2A20` ×22, `9E9287` ×21, `E3A66C` ×18, `D96C32` ×17, `1A1715` ×14, `E86A3A` ×10, `241A16` ×10, `E17A43` ×9, `332824` ×9, `5A3023` ×8, `49352A` ×8, `231915` ×8. | Medio: cambiare una tinta vuol dire toccare decine di file. | Nuovi token in `AmaterasuColors` con lo stesso valore, ad es. `textPrimary` (F2E7D5), `textSecondary` (B7A99B), `textMuted` (9E9287), `surfaceDeep` (100C0A), `surface` (1A1512), `surfaceAlt` (1A1715), `surfaceRaised` (241A16), `borderWarm` (3A2A20), `borderAccent` (5A3023), `accentBudget` (D96C32), `accentSettings` (E28A32), `accentGold` (E3A66C), `accentOrange` (E17A43), `accentFlame` (E86A3A). I colori usati 1-2 volte restano scritti a mano con un commento. | nessuno (passo b) |
| ST2 | 69 costanti locali (es. `const cream = Color(0xFFF2E7D5)` ×12, `const muted = Color(0xFFB7A99B)` ×11, `const gold = Color(0xFFE3A66C)` ×8, `const orange = Color(0xFFE17A43)` ×5) | Gli stessi colori ridichiarati come costanti dentro i singoli file o metodi. | Basso. | Puntarle ai nuovi token. | nessuno (passo b) |
| ST3 | `lib/core/theme/amaterasu_spacing.dart`, `amaterasu_radius.dart` | Token quasi inutilizzati (Spacing 1 uso, Radius 8 usi). Valori più usati nel codice: raggi 12 (×40), 18 (×31), 17 (×22), 14 (×20), 16 (×17), 20 (×15); spazi `SizedBox` 8 e 10 (×86), 12 (×77), 14 (×59), 4 (×41); `EdgeInsets.all(16)` ×25, `(24)` ×14. | Basso. | Aggiungere token con gli stessi valori (es. `AmaterasuRadius.r12/r16/r18`) e usarli solo nei file toccati nel passo b, senza cambiare numeri. Raggio 17 e spazio 10 non hanno corrispondenti: restano a mano. | nessuno (passo b, parziale) |
| ST4 | `lib/core/theme/amaterasu_colors.dart` | `primary` (E5482E), `background` (1A0B08) e gli altri 5 colori del tema non compaiono scritti a mano: sono usati solo tramite token (20 usi) e dal tema Material. | — | Nessuna: restano come sono. | — |

## 5. Localizzazioni

Stato: 1.143 chiavi sia in italiano sia in inglese, nessuna mancante, nessun valore vuoto, `tool/check_l10n.dart` OK.

| ID | File / riga | Problema | Rischio | Correzione proposta | Impatto |
|---|---|---|---|---|---|
| L1 | `lib/l10n/app_it.arb`, `app_en.arb` | Nessuna chiave doppia. (Le 7 "doppie" segnalate da una ricerca semplice, `name`, `email`, `type`…, sono nomi di segnaposto dentro le descrizioni `@chiave`: corretto.) | — | Nessuna. | — |
| L2 | `lib/l10n/*.arb` | **178 chiavi mai usate** nel codice: 61 `tripNotifications*` (notifiche rimosse), 22 `tripQuestionnaire*`, 20 `privacyPolicy*`, 15 `b6*`/`b86History`, 8 `tripTravellers*`, 7 `tripManagement*`, 6 `tripCover*Permission*`, 6 `profilePhoto*`, 4 `accountLinked*`, e altre singole (`homeGoogleUser`, `homeNoUid`, `settingsPlaceholder`, `commonPassword`, `authEmailOrUsernameHint`…). | Basso: ~15% del file da tradurre e mantenere per niente. | Eliminarle da entrambe le lingue e rigenerare. Se una chiave fosse ancora usata, la compilazione fallirebbe: è un controllo sicuro. | nessuno (passo c) |
| L3 | `lib/l10n/app_it.arb` | 93 gruppi di testi identici in più chiavi (247 chiavi): "Annulla" ×13, "Altro" ×8, "Da saldare" ×8, "Continua" ×6, "Trasporti" ×5, "Prevista" ×5, "Conferma" ×4, "Salva" ×4… | Basso. | Unire solo i doppioni dentro la stessa area (es. le chiavi budget `btListPlanned`/`btDetailsPlanned`/`btToolbarPlanned`/`btCreatePlanned` → una `budgetStatusPlanned`); lasciare separate le chiavi di aree diverse (in futuro possono cambiare indipendentemente). | nessuno (passo c) |
| L4 | `lib/l10n/app_it.arb:656-657` | `tripTravellersOwnerRole` = "OWNER" e `tripTravellersTravelerRole` = "TRAVELER" anche in italiano. Gli altri 28 testi uguali tra italiano e inglese sono corretti (Password, Email, Bucket List, Google Drive…). | Basso. | Tradurre ("PROPRIETARIO", "VIAGGIATORE")? | da decidere io (cambia un testo visibile) |
| L5 | `lib/features/trips/presentation/pages/workspace/bucket_list/` (8 file, ~137 testi), `lib/features/trips/presentation/pages/workspace/settings/travellers/trip_traveller_profile_edit_page.dart` (19 testi) | Testi scritti nel codice con `_t('italiano', 'english')` (`bucket_method_translation.dart:5`, `trip_traveller_profile_edit_page.dart`). | Medio: non passano dal controllo traduzioni, terza lingua impossibile. | Spostarli in `lib/l10n`, un file alla volta, con gli stessi testi. | da decidere io (bucket list e gestione viaggio sono approvate; il testo mostrato resta identico) |
| L6 | `lib/features/auth/presentation/widgets/login_card.dart:249, 258`, `lib/features/settings/presentation/pages/account/account_logout.dart:21`, `lib/features/trips/presentation/pages/workspace/bucket_list/bucket_method_page_view.dart:558`, `google_drive_folder_browser_page.dart:159, 523` | Testi solo in italiano scritti nel codice (in inglese l'utente li vede in italiano). | Basso. | Spostarli in `lib/l10n` con traduzione inglese. | da decidere io (in inglese il testo cambia; login e logout sono in aree finite/approvate) |
| L7 | chiavi ARB | Nomi incoerenti: prefissi legati alle fasi di sviluppo (`b6*` 42, `b85*` 6, `b86*` 30, `bt*` 224) accanto a `budget*` 43; `Traveller` (64 chiavi) e `Traveler` (10); chiavi senza area (`name`, `email`, `uid`, `confirm`, `cancel`, `logoutTest`…). Anche nei file: `travellers/` vs `budget_traveler_*`. | Basso. | Rinominare è un lavoro grande e a rischio di errori di battitura: propongo di fissare la regola nel CLAUDE.md (prefisso = area, inglese americano `traveler`) e applicarla solo alle chiavi nuove. | nessuno (solo convenzione, passo g) |
| L8 | `lib/l10n/app_en.arb` | 21 descrizioni `@chiave` esistono solo in inglese (es. `@b86ClosedBy`, `@btCreateShare`). | Nessuno: le descrizioni servono solo nel file modello. | Nessuna, oppure copiarle anche in italiano. | nessuno |

## 6. Documentazione

| ID | File / riga | Problema | Rischio | Correzione proposta | Impatto |
|---|---|---|---|---|---|
| D1 | `README.md` | È il testo predefinito di Flutter ("A new Flutter project."). | Medio: nessuno sa come avviare, testare o pubblicare. | README vero: cos'è, requisiti, avvio (con le `--dart-define` per Maps, Drive, App Check), struttura cartelle, test (`tool/check_all.sh`), pubblicazione Web (copia di `hosting/` in `build/web`). | nessuno (passo g) |
| D2 | `CLAUDE.md` | Stato non più esatto: cita il QR (C11) e TripWorkspaceHeader/Card come componenti (C1); budget "in corso" anche se è uscita la 1.10.0; mancano le convenzioni nuove. | Basso. | Aggiornare con convenzioni (file piccoli, intestazione, moduli condivisi, token) e il permesso di riordinare la struttura mantenendo il comportamento. | nessuno (passo g) |
| D3 | `pubspec.yaml:2` | Descrizione "Japan Travel Planner": il progetto non è solo per il Giappone. | Nessuno. | "Amaterasu Trip - organizzazione dei viaggi". | nessuno (passo g) |
| D4 | `docs/` | C'è solo `privacy.html` e la checklist budget; nessuna documentazione delle Cloud Functions o delle collezioni Firestore. | Basso. | Elenco funzioni e collezioni nel README (solo descrizione, nessun cambiamento). | nessuno (passo g) |
| D5 | `functions/package.json` | Nessuno script `test`: i test node si lanciano a mano con percorsi diversi (alcuni vogliono il percorso del file compilato come argomento). | Basso. | Già raccolti in `tool/check_all.sh`; documentarli nel README. | nessuno (passo g) |

---

## Riepilogo

| Area | Voci | Impatto "nessuno" | Da verificare | Da decidere io | Solo informative |
|---|---|---|---|---|---|
| 1. Sicurezza | 13 | 2 (S3 parte minor, S4) | 3 (S5, S6, S7) | 4 (S1, S2, S10, S13) + S3 parte maggiore | 4 (S8, S9, S11, S12) |
| 2. Build e portabilità | 11 | 6 (B1, B2, B3, B4, B9, B11) | — | 4 (B5, B7, B8, B10) | 1 (B6) |
| 3. Codice | 15 + elenco file grandi | 8 (C1 parte sicura, C3, C6, C8, C12 minor/patch, C13, C14, C15) + 20 file grandi | 2 (C7, C11) | 5 (C2, C4, C5, C9, C10) + 26 file grandi | — |
| 4. Stile | 4 | 3 (ST1, ST2, ST3) | — | — | 1 (ST4) |
| 5. Localizzazioni | 8 | 4 (L2, L3, L7 convenzione, L8) | — | 3 (L4, L5, L6) | 1 (L1) |
| 6. Documentazione | 5 | 5 (D1-D5) | — | — | — |
| **Totale** | **56** | **28** | **5** | **16** | **7** |

(Alcune voci sono divise in una parte "nessuno" e una "da decidere io", ad esempio S3, B7, C1, C12: sono contate una volta sola, dove cade la parte principale. La parte "documentazione" di B7 rientra in D1.)

### Voci a impatto "nessuno", nell'ordine in cui le farei (Fase 2)
- **a)** B1 import maiuscoli · B2 `.gitattributes` · B3 togliere `rules-tests/node_modules` da git · B4 `.gitignore` · B11 cartella vuota · C1 file morti sicuri (probe E2EE, `external_locale`, `budget_overview`, `bucket_vote`, roster provider).
- **b)** ST1-ST3 nuovi token con gli stessi valori e sostituzione dei colori scritti a mano.
- **c)** B9 `l10n.yaml` (solo se rigenera file identici) · L2 chiavi inutilizzate · L3 doppioni dentro la stessa area. (Nessuna traduzione manca. I testi nel codice, L5/L6, sono "da decidere".)
- **d)** C6, C8 moduli condivisi del budget · C13, C14 helper condivisi nelle functions · divisione dei 20 file grandi non approvati (budget, router, panoramica, login, 4 TypeScript).
- **e)** Intestazioni in tutti i file Dart scritti da noi (anche C3) e `// TODO(audit)` sulle voci segnalate (es. S5).
- **f)** S3 e S4 `npm audit fix` senza `--force` · C12 aggiornamenti minor/patch.
- **g)** D1-D5 e convenzione L7 nel CLAUDE.md.

### Cose da decidere prima del "procedi"
1. **Funzioni approvate.** I passi b (colori) ed e (intestazioni) toccano per forza anche file di gestione viaggio, impostazioni e bucket list, ma solo nella forma: stessi valori, nessun cambiamento visibile. Il tuo "procedi" vale anche per questo? Se no, li salto in quelle cartelle. Divisione dei 26 file grandi approvati e spostamento dei testi `_t(...)` (L5) restano esclusi finché non me lo chiedi.
2. Le voci "da decidere io" (S1, S2/B5, S10, B8, B10, C2, C4, C5, C7, C9, C10, C11, L4, L6) restano nel report e non le tocco.
