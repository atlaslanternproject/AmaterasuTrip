# Audit Trail: analisi (tappa 4, solo analisi, nessun codice)

Scritto il 25/11/2026. Principi ispirati alla 21 CFR Part 11
(attribuibilità, ora affidabile, registro non modificabile, valore prima
e dopo) usati **solo come ispirazione**: Amaterasu Trip non è e non si
dichiara conforme alla 21 CFR Part 11 né ad altre norme.

## 1. Cosa esiste oggi

| Area | Chi scrive | Autore | Ultima modifica | Storico |
|---|---|---|---|---|
| Sezioni nuove (trasporti, prenotazioni, ristoranti, luoghi, note, shopping, checklist, ricordi, categorie) | l'app, direttamente | `createdByUid` = chi crea (regole: `sectionCreateOk`), non modificabile (`sectionUpdateOk`) | solo `updatedAt` = ora del server (`sectionBase`); **chi** ha modificato non è salvato | nessuno: una modifica sovrascrive |
| Alloggi (approvato) | l'app | `createdByUid` (regole, righe ~793-812) | solo `updatedAt` | nessuno |
| Bucket list (approvata) | l'app; approvazione della cancellazione con la funzione `approveBucketActivityDeletion` | `createdByUid`; voti per utente | nessun "modificato da" | richieste di cancellazione (`deletionRequests`) con esito |
| Budget (approvato) | **solo il server** (le regole negano ogni scrittura dall'app su `budgetSharedExpenses` e `budgetPrivateOwners`) | `createdByUid` e attori negli eventi | versione della spesa | **sì**: `revisions`, `reimbursements`, `cancellationLog`, `fxRateChanges`, `categoryChanges`, non modificabili dall'app; letti dalla funzione `listBudgetHistory` (solo spese condivise in cui partecipi e le tue private, al massimo 500 eventi, senza pagine) e mostrati in "Storico" (B8.4-B8.7) |
| Note e checklist private | l'app | autore | — | le leggono solo gli autori (regole e test) |

`updatedByUid` non esiste in nessun documento, regola o funzione (cercato
in lib/, functions/src/ e firestore.rules).

Cancellazione dell'account (client, batch): toglie profilo
(`viaggiatori/{uid}`), username e segnalazioni. Nei viaggi restano gli
identificativi (`createdByUid`) degli elementi creati; il nome si ricava
dal profilo, che non c'è più, quindi oggi si vede "Viaggiatore" (testo di
riserva del budget e delle sezioni), non "Utente eliminato".

## 2. Cosa mancherebbe rispetto al prompt
1. `updatedByUid` obbligato dalle regole in sezioni nuove e alloggi.
2. Registro `trips/{tripId}/auditTrail` scritto solo dal server, non
   modificabile né cancellabile da nessuno (nemmeno OWNER).
3. Per ogni voce: chi (uid, nome risolto alla lettura), cosa (sezione,
   elemento, azione), quando (ora del server), valore prima/dopo dei soli
   campi cambiati.
4. Mai contenuti privati: note e checklist private non entrano nel
   registro (nemmeno titolo o esistenza, perché il registro lo vedono tutti
   i membri).
5. "Utente eliminato" per gli account cancellati.
6. Voce "Audit Trail" in Altro con i filtri condivisi (sezione, persona,
   azione, periodo), a pagine da 30.
7. Integrazione dello storico del budget senza toccarlo.

## 3. Tre opzioni (dalla più semplice alla più completa)

### Opzione A - "Modificato da" (nessun registro)
- `updatedByUid` in sezioni nuove e alloggi: le regole lo obbligano uguale
  a chi scrive (`request.auth.uid`) a ogni creazione e modifica; le card e
  "Dettagli" mostrano "Modificato da Yato il 12/04 alle 10:30".
- Lavoro: piccolo (modulo comune delle sezioni, codec, regole e test;
  alloggi: modulo approvato, serve il tuo ok per codec e regole).
- Regole: +2 controlli in `sectionBase` / regola degli alloggi (lontano dal
  limite di 1000).
- Costi: zero letture e scritture in più.
- Privacy: nessun dato nuovo oltre a un identificativo già presente nei
  viaggi; informativa: una riga ("salviamo chi ha fatto l'ultima modifica").
- Limite: non c'è storia (si vede solo l'ultima modifica), nessun valore
  prima/dopo.

### Opzione B - Registro dal server con trigger (sezioni nuove)
- Tutto A, più una Cloud Function per ogni scrittura nelle collezioni
  delle sezioni nuove (trigger Firestore v2 "onDocumentWritten" con il
  contesto dell'utente, oppure `updatedByUid` come fonte affidabile
  dell'autore) che aggiunge un documento in `trips/{tripId}/auditTrail`:
  `{at (ora del server), actorUid, section, itemId, itemName, action
  (create|update|delete), changes: {campo: {before, after}}}`.
- Esclusi: documenti privati (note e checklist con visibilità privata,
  prima e dopo), campi sensibili anche se condivisi (codice porta,
  password Wi-Fi: si registra solo "cambiato"), testi lunghi tagliati a
  200 caratteri.
- Regole: `match /auditTrail/{id}`: lettura (get/list) per i membri;
  create, update, delete **false per tutti** (scrive solo il server con i
  privilegi di amministratore). Nessun annullamento dal registro.
- Funzioni: +1 funzione a trigger (34 in tutto); il controllo della
  pubblicazione va aggiornato.
- Costi (prezzi e quote di COSTI.md): ogni modifica di un elemento = 1
  invocazione in più + 1 scrittura in più. Un viaggio con 4 persone e 300
  modifiche: 300 invocazioni e 300 scritture in tutto il viaggio; la
  pagina legge 30 documenti per pagina, solo quando si apre. Con 20 utenti
  attivi al giorno restiamo molto sotto le quote gratuite (20.000
  scritture al giorno, 2 milioni di invocazioni al mese). Indici: 3
  indici composti (sezione, persona, azione con data), spazio trascurabile.
- Duplicazione del viaggio: `auditTrail` escluso (come le sezioni);
  eliminazione del viaggio: cancellato con le sottoraccolte (deleteTrip lo
  fa già per tutte).
- Lavoro: medio (funzione, regole e test con emulatore, pagina con filtri
  condivisi e pagine da 30, indici).
- Privacy: il registro conserva i valori vecchi dei campi condivisi (es.
  un vecchio orario o indirizzo) finché esiste il viaggio; li vedono solo i
  membri; serve una sezione nell'informativa ("registro delle modifiche
  del viaggio: chi, cosa, quando, visibile ai membri, cancellato con il
  viaggio").

### Opzione C - Registro completo con alloggi, bucket list e budget
- Tutto B, più:
  - **Alloggi**: stesso trigger sulla raccolta `stays` (il trigger non
    cambia il modulo, ma `updatedByUid` sì: codec e regole degli alloggi,
    serve il tuo ok).
  - **Bucket list**: trigger su `bucketList` (escluse le singole
    votazioni, troppe e poco utili; incluse creazione, modifica,
    cancellazione e l'esito delle richieste di cancellazione). Il trigger
    non cambia la bucket list; `updatedByUid` invece sì (codec e regole
    della bucket list, modulo approvato: serve il tuo ok).
  - **Budget, senza toccarlo**: la pagina Audit Trail chiama in sola
    lettura la funzione esistente `listBudgetHistory` (stesse regole di
    visibilità: spese condivise in cui partecipi e solo le tue private) e
    mostra quegli eventi insieme al registro, con il filtro "Spese". Non si
    copiano nel registro (le spese private resterebbero visibili a tutti).
    Limite: `listBudgetHistory` restituisce al massimo 500 eventi senza
    pagine; per le pagine da 30 servirebbe un parametro in più nella
    funzione (modifica del budget: solo con il tuo ok). Alternativa senza
    toccarlo: il filtro "Spese" apre lo "Storico" del budget già esistente.
  - "Utente eliminato": i nomi si risolvono alla lettura (stessa funzione
    condivisa dei nomi, regola 2); se il profilo non c'è più si mostra
    "Utente eliminato" invece di "Viaggiatore". Il registro conserva solo
    l'identificativo, mai nome o email, così la cancellazione dell'account
    non richiede di riscrivere il registro (che resta non modificabile).
  - Esportazione del registro in CSV (sola lettura, lib/core/files).
- Costi: come B più le scritture degli alloggi e della bucket list (stesso
  ordine di grandezza); il budget non aggiunge scritture.
- Lavoro: grande; tocca due moduli approvati per `updatedByUid`.

## 4. Impatto riassunto

| | A | B | C |
|---|---|---|---|
| Regole | +2 controlli per raccolta | A + `auditTrail` sola lettura | B + alloggi e bucket list |
| Funzioni | nessuna | +1 trigger (34) | +1 o 2 trigger |
| Letture | 0 | 30 per pagina, su richiesta | B + 1 chiamata a `listBudgetHistory` |
| Scritture | 0 | +1 per modifica | +1 per modifica (anche alloggi e bucket list) |
| Moduli approvati | alloggi (solo per `updatedByUid`) | nessuno | alloggi, bucket list; budget solo in lettura (o +1 parametro con ok) |
| Privacy | 1 riga di informativa | sezione nuova nell'informativa | come B + nomi "Utente eliminato" |

## 5. Proposta
Procedere con **B** (registro delle sezioni nuove, nessun modulo approvato
toccato), con l'integrazione del budget **in sola lettura** come in C
(filtro "Spese" che apre lo Storico esistente, senza cambiare
`listBudgetHistory`), e decidere alloggi e bucket list nel giro di
COERENZA.md. Prima del codice: test delle regole con emulatore
(nessuno scrive, membri leggono, esterni no), test del trigger (privati
esclusi, campi sensibili solo "cambiato", testi tagliati), informativa
aggiornata nello stesso rilascio.

Non costruisco nulla finché non scegli l'opzione.
