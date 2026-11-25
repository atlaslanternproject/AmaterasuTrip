# Coerenza tra i moduli: voci per il giro finale

Elenco delle differenze trovate durante il prompt v2 che riguardano i
moduli approvati (bucket list, budget, gestione viaggio, impostazioni,
alloggi). Nessuna è stata applicata: si decidono insieme nella tabella
finale (tappa "Tabella COERENZA.md"), dopo il tuo ok voce per voce.

| # | Modulo | Differenza | Proposta | Origine |
|---|---|---|---|---|
| 1 | Alloggi | Cerca apre la pagina degli alloggi senza mettere in risalto l'elemento trovato (le sezioni nuove lo fanno dalla 1.53.0) | Usare lo stesso segno (tripSectionFocusProvider) nell'elenco degli alloggi: scorre fino all'alloggio e lo evidenzia 3 secondi | Tappa 2b, decisione del 25/11/2026: non ora |
| 2 | Alloggi | Editor al 130 % su telefono: escono dallo spazio i titoli delle sezioni a tendina (trip_stay_editor_section.dart:34) e la tendina "Prenotato su" (trip_stay_booking_section.dart:39) | Stessa correzione delle sezioni nuove (testo flessibile) | Extra E3 |
| 3 | Budget, alloggi, bucket list, impostazioni | Formato di data e ora di Aspetto non ancora applicato | Usare AmaterasuDates come nelle sezioni nuove | Extra E4 |
| 4 | Impostazioni del viaggio | Mostrano ancora il nome completo invece dello username | Usare la funzione condivisa del nome (regola 2) | Regola 2 |
| 5 | Bucket list, impostazioni | Non provate al 130 % con il test automatico | Prova a mano o test con dati di prova | Extra E3 |
| 6 | Bucket list | Ha ancora le sue copie di link e luoghi (TODO(audit)) | Passare ai moduli comuni lib/core/links e lib/core/places | Audit |
