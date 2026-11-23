# Amaterasu Trip

Piattaforma per organizzare e gestire un viaggio: una vacanza, un weekend
o un'uscita di un giorno. L'utente crea il viaggio, invita gli altri
viaggiatori e raccoglie in un unico posto attività, budget, spese e note.
Non usa l'intelligenza artificiale per generare itinerari.

Stack: **Flutter** (Android, iOS, Web) + **Firebase** (Auth, Firestore,
Storage, Cloud Functions, Hosting, App Check).

## Stato

| Area | Stato |
|---|---|
| Accesso e account (email/password, Google, verifica email) | completo |
| Profilo utente | completo |
| Impostazioni globali | completo |
| Gestione del viaggio (creazione, inviti, viaggiatori, impostazioni) | completo |
| Panoramica e workspace del viaggio | completo |
| Bucket list (attività condivise, voti, cancellazione approvata) | completo |
| Budget e spese | rilasciato nella 1.10.0 |
| Hotel e alloggi (tipo, contatti, foto Google, filtri, costo previsto, cancellazione gratuita, servizi) | rilasciato nella 1.11.0, card nuova nella 1.12.0, migliorie nella 1.15.0 |
| Trasporti (tipo, da/a, orari con fuso, passeggeri, avvisi di coincidenza, spesa) | rilasciato nella 1.16.0 |
| Prenotazioni (biglietti, ingressi, tour, escursioni, partecipanti, cancellazione, spesa) | rilasciato nella 1.17.0 |
| Itinerario, mappa, ristoranti, luoghi salvati, note, shopping, ricordi | pagine segnaposto, da sviluppare |

## Requisiti

- Flutter 3.44 (stable) con Dart 3.12
- Node.js 22 e npm (Cloud Functions e test)
- Firebase CLI (`npm install -g firebase-tools`)
- Java 21+ (per gli emulatori Firebase)
- Android SDK per la build Android

## Avvio

```bash
flutter pub get
npm --prefix functions install
npm --prefix rules-tests install

# Android / iOS
flutter run

# Web: la chiave di Google Maps arriva da un file locale non salvato in git
flutter run -d chrome --dart-define-from-file=.env.local.json
```

Valori passati con `--dart-define` (mai scritti nel codice):

| Nome | Dove serve |
|---|---|
| `GOOGLE_MAPS_WEB_API_KEY` | Google Maps e ricerca luoghi sul Web (in `.env.local.json`) |
| `GOOGLE_DRIVE_WEB_CLIENT_ID` | archivio del viaggio su Google Drive dal Web |
| `AMATERASU_RECAPTCHA_SITE_KEY` | App Check sul Web |
| `AMATERASU_WEB_APP_CHECK_DEBUG` | `true` per usare il token di debug di App Check sul Web |
| `AMATERASU_LOCAL_TEST` | `true` per la variante Android di test locale (vedi sotto) |

`.env.local.json` è escluso da git: va creato a mano, ad esempio
`{"GOOGLE_MAPS_WEB_API_KEY": "..."}`.

### Variante di test locale (Android + emulatori)

Con la variabile d'ambiente `AMATERASU_LOCAL_TEST=1` Gradle crea la variante
`localtest`; l'app, avviata con `--dart-define=AMATERASU_LOCAL_TEST=true`,
si collega agli emulatori Firebase (`firebase.emulators.security-test.json`)
e al progetto finto `demo-amaterasu-security`, mai a quello reale.

## Struttura delle cartelle

```
lib/
  main.dart              avvio: Firebase, App Check, Google Maps
  app/                   widget radice e rotte (GoRouter)
  core/                  parti comuni a tutta l'app
    theme/               token: AmaterasuColors, AmaterasuSpacing, AmaterasuRadius
    widgets/             componenti riutilizzabili (card, bottoni, campi, barre)
    navigation/ maps/ media/ security/ storage/
  features/              una cartella per area
    auth/                accesso e registrazione
    home/
    profile/             profilo utente
    settings/            impostazioni globali e account
    trips/               viaggi
      bucket_list/       attività condivise e voti
      budget/            spese, rimborsi, budget personale
      data/ models/ providers/ domain/
      presentation/      pagine (creazione, invito, workspace del viaggio)
  l10n/                  testi tradotti (app_it.arb, app_en.arb) e file generati
functions/src/           Cloud Functions (TypeScript), una funzione per file
  trip-invites/ trip-members/ trip-management/ bucket-list/ budget/
  account-deletion/ shared/
functions/test/          test node e test con gli emulatori
rules-tests/             test delle regole Firestore
test/                    test Flutter (unitari e di widget)
hosting/                 pagine statiche: invito, cancellazione account/dati
tool/                    script: check_all.sh, check_l10n.dart
docs/                    privacy, checklist manuali del budget, audit
firestore.rules          regole di sicurezza di Firestore
```

File grandi divisi in più parti: molte schermate usano file `part`
(es. `budget_create_dialog.dart` con `budget_create_dialog_save.dart`),
che sono pezzi dello stesso file, non componenti separati.

## Test

Un solo comando esegue tutti i controlli automatici (da Git Bash, dalla
cartella principale):

```bash
bash tool/check_all.sh
```

Esegue: `flutter pub get` e `flutter gen-l10n` (così i testi generati
esistono sempre prima dell'analisi), `flutter analyze`, `flutter test`,
il controllo delle traduzioni,
lint e build delle Cloud Functions, i test node e i test con gli
emulatori: budget (regole, privacy, integrazione, "segna come pagato"),
regole Storage, regole Firestore (soggiorni, 21 test generali, B7.1,
B7.5.2) e `deleteTrip` con le copertine.
Gli emulatori usano solo progetti `demo-*`.

Altri test da lanciare a parte:

```bash
# rimozione di un viaggiatore (Cloud Function con emulatori)
firebase emulators:exec --config firebase.emulators.security-test.json \
  --project demo-amaterasu-security --only firestore,auth,functions \
  "node functions/test/remove_trip_member.emulator.cjs"
```

Le prove manuali del budget sono in `docs/budget-checklist-prove-manuali.md`.

## Traduzioni

I testi stanno in `lib/l10n/app_it.arb` e `lib/l10n/app_en.arb`; i file
`app_localizations*.dart` sono generati (`flutter gen-l10n`, impostazioni
in `l10n.yaml`). Per aggiungere una lingua: creare `lib/l10n/app_XX.arb` con
esattamente le stesse chiavi di `app_it.arb`, tradurre i valori e lanciare
`dart run tool/check_l10n.dart`.

## Pubblicazione

Il deploy si fa solo a mano, dopo i controlli.

- **Cloud Functions**: `firebase deploy --only functions` (lint e build
  partono da soli prima del deploy).
- **Regole Firestore**: `firebase deploy --only firestore:rules`.
- **Web**: `flutter build web --dart-define-from-file=.env.local.json`, poi
  copiare a mano le pagine di `hosting/` (invito e cancellazione) dentro
  `build/web`, poi `firebase deploy --only hosting`. Senza la copia la
  pagina di invito non viene pubblicata.
- **Regole Storage**: `firebase deploy --only storage` (file
  `storage.rules`, provate da `rules-tests/storage-rules.test.cjs`, che
  fa parte di `tool/check_all.sh`).

Script una tantum: `functions/scripts/budget-backfill-participants.cjs`
aggiorna le spese vecchie; parte in prova e scrive solo con `--apply`.

## Versioni

Formato `X.Y.Z+build` (in `pubspec.yaml`): Y per una novità grande
(es. budget completo → 1.10.0), Z per le correzioni di errori; il numero di
build sale di 1 a ogni rilascio. La 2.0.0 è riservata alla prima versione
pubblicata: fino ad allora si resta su 1.x (1.10, 1.11, …).
