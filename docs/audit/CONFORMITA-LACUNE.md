# Conformità: lacune da far rivedere (Extra F)

Data: 25/11/2026. Elenco delle cose che la pagina "Conformità e normative"
segna come lacuna o "da verificare". Da far rivedere a un professionista
(privacy/legale) PRIMA dell'uscita pubblica. Non è consulenza legale.

## Fatti verificati (base della tabella)
- Firestore: database (default), regione eur3 (Unione Europea), letta con
  `firebase firestore:databases:get`.
- Cloud Functions: europe-west1 (codice in functions/src).
- Informativa privacy online: https://atlaslanternproject.github.io/AmaterasuTrip/privacy.html
- Termini d'uso: NON esiste una pagina.
- Browser: preferenze tecniche in SharedPreferences (localStorage):
  app_language, appearance.v1, whatsNew.lastSeenVersion, viste delle
  sezioni, impostazioni dei dati, foto in attesa di caricamento; accesso
  Firebase (IndexedDB). Nessuno strumento di analisi o statistica.
- App Check sul web: reCAPTCHA Enterprise (lib/core/app_check).
- Google Drive: permesso drive.file (solo i file creati dall'app).
- Cancellazione account: in app (Impostazioni > Account), con profilo e
  foto.

## Lacune e punti da verificare
1. Termini d'uso: da scrivere e pubblicare (oggi c'è solo l'informativa).
2. Portabilità (GDPR art. 20): manca l'esportazione dei propri dati in un
   file (oggi c'è solo l'esportazione delle spese del viaggio).
3. Segnalazioni e idee (raccolta feedback): restano dopo la cancellazione
   dell'account; andrebbero cancellate insieme (tocca la funzione di
   cancellazione, modulo approvato: serve il tuo ok). Aggiornare anche
   l'informativa privacy con questa raccolta.
4. reCAPTCHA Enterprise (App Check): verificare se i suoi cookie sono
   "tecnici" ai sensi delle linee guida del Garante e se serve un avviso o
   un banner; citarlo nell'informativa.
5. Google Maps Platform: telefono e sito presi da Google vengono copiati nei
   campi dell'utente e salvati (alloggi, ristoranti, luoghi). Verificare
   con i termini sulla conservazione dei contenuti; in alternativa salvarli
   solo se l'utente li conferma o li modifica.
6. Minori: l'app non chiede l'età (Codice Privacy art. 2-quinquies, 14
   anni): verificare se serve un'età minima nei termini.
7. Accordi con Google: verificare l'accettazione dei termini sul
   trattamento dei dati (Data Processing Addendum) in Firebase e Google
   Cloud e la regione di Cloud Storage (non letta: da verificare).
8. Base giuridica e registro dei trattamenti: da definire con il
   professionista.
9. Verifica dell'app OAuth (Google Drive) per l'uso pubblico: da fare
   prima dell'uscita.
10. Audit Trail (ispirato alla 21 CFR Part 11): non ancora costruito;
    quando ci sarà, descriverlo nell'informativa.
