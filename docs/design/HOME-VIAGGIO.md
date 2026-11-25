# Home del viaggio per fase: piano tecnico

Scritto il 25/11/2026. La home del viaggio fa parte di "gestione viaggio"
(modulo approvato): **la costruisco solo dopo il tuo ok**. Direttive:
docs/design/DIRETTIVE-UI.md ("Home del viaggio per fase"); tabella
COERENZA.md, gruppo C.

## 1. Oggi
`workspace/overview/trip_overview_page.dart` (+ hero, hero_parts,
widgets; 571 righe): copertina in testa (resta com'è), poi tre riquadri
(Itinerario, Bucket list, Altro) che ripetono la barra inferiore e
lasciano spazio vuoto; 27 colori scritti a mano.

## 2. Struttura proposta
- Sopra: la copertina attuale, invariata (titolo, date, destinazione).
- Sotto: una **dashboard per fase**, scelta dalle date del viaggio nel
  fuso del dispositivo:
  - **Prima**: oggi < giorno di inizio;
  - **Durante**: inizio ≤ oggi ≤ fine;
  - **Dopo**: oggi > fine.
- Spariscono i tre riquadri che ripetono la barra.
- Ogni riquadro della dashboard è un componente piccolo (un file ciascuno,
  sotto le 200 righe) in `workspace/overview/phases/`; la pagina sceglie
  l'elenco dei riquadri in base alla fase. Nessun tema legato alla
  destinazione, nessuna illustrazione (solo l'icona del sole nel conto
  alla rovescia).

## 3. Riquadri per fase e da dove prendono i dati
| Riquadro | Fase | Dati (già esistenti) |
|---|---|---|
| Conto alla rovescia ("mancano 12 giorni", icona sole) | Prima | date del viaggio |
| Prontezza voce per voce (✔/✖): alloggio per ogni notte, trasporto di andata e ritorno, checklist "Valigia" completata, budget impostato | Prima | avviso delle notti senza alloggio degli alloggi (trip_stays_gaps), trasporti, checklist, budget personale |
| Prossime scadenze (da prenotare entro, cancellazione gratuita, check-in online) | Prima | prenotazioni (`bookBy`), alloggi (`freeCancellationUntil`), trasporti (`checkInHoursBefore`) |
| Meteo | Prima, Durante | tripWeatherProvider (1 chiamata per sessione, cache condivisa sul server) |
| Spese finora | Prima, Durante | totali del modulo condiviso del budget (budget_category_totals.dart) |
| Checklist valigia (avanzamento) | Prima | checklist con modello Valigia |
| Debiti aperti ("devi 20 € a Yato") | Prima, Durante, Dopo | BudgetDebtOverviewCalculator (budget, sola lettura) |
| "Oggi" in ordine di orario | Durante | elementi con data di oggi da alloggi, trasporti, prenotazioni, ristoranti (e poi Itinerario, quando c'è) |
| Prossimo evento | Durante | il primo elemento di "Oggi" non ancora passato |
| Ora locale | Durante | fuso della destinazione dalla risposta del Meteo (`forecast.timezone`) con AmaterasuZoneClock; altrimenti dal primo alloggio con fuso |
| Spese di oggi | Durante | totali per giorno del modulo del budget (`daily`) |
| Numeri di emergenza | Durante | Info paese (file dell'app, nessuna rete) |
| Pulsanti rapidi (Aggiungi spesa, Aggiungi nota) | Durante | dialogo "Crea spesa" esistente, editor delle note |
| Statistiche (tre numeri, ciambella per categoria) | Dopo | Statistiche (TripStats + totali del budget, BudgetCategoryChart) |
| Conti da saldare | Dopo | come "Debiti aperti" |
| Link ai ricordi e PDF | Dopo | Ricordi (album), cartella del viaggio, Esporta (PDF) |

## 4. Costi e letture
- Una sola lettura all'apertura della home per sessione (provider tenuto
  per la sessione con "Aggiorna"), con gli store delle sezioni: nessun
  ascoltatore sempre attivo.
- Spese: una lettura delle spese condivise e private (come il cruscotto).
- Meteo: la stessa chiamata della pagina Meteo (cache condivisa per
  viaggio, nessuna chiamata in più se già fatta nella sessione).
- Nessuna nuova API, nessuna nuova funzione sul server, nessuna regola
  nuova.

## 5. Cosa tocca
- Modulo approvato "gestione viaggio": solo la pagina della home del
  viaggio (overview) e i suoi file; copertina invariata.
- Budget: solo lettura (calcolatori esistenti).
- Colori: token di AmaterasuColors al posto dei 27 colori scritti a mano.

## 6. Test
- Scelta della fase con date di prova (giorno prima dell'inizio, primo
  giorno, ultimo giorno, giorno dopo).
- Ogni riquadro con dati finti (vuoto e pieno), "Oggi" in ordine di
  orario, prossimo evento.
- Debiti e spese uguali a quelli del budget (stessi calcolatori).
- 130 % su telefono e schermo largo senza errori di spazio.
- Test esistenti della home e della barra inferiore invariati.

## 7. Ordine di costruzione (un rilascio per passo, dopo l'ok)
1. Struttura per fase e conto alla rovescia, via i riquadri ripetuti.
2. Prima: prontezza, scadenze, checklist valigia.
3. Durante: Oggi, prossimo evento, ora locale, numeri di emergenza,
   pulsanti rapidi.
4. Meteo e spese (finora / di oggi), debiti aperti.
5. Dopo: statistiche, conti da saldare, ricordi e PDF.
