# Budget 2: analisi (tappa K, solo analisi, nessuna modifica)

Scritto il 25/11/2026. Il budget è un modulo approvato: nulla di questo
documento si costruisce senza il tuo ok, punto per punto. Regola comune a
tutti i punti: i calcoli dei soldi restano sul server (Cloud Functions) e
in unità minime intere; ogni cambiamento ai calcoli va con i test di
parità app/server (budget-calc-parity) e le 3 suite con emulatori prima e
dopo.

## Stato di partenza (cosa esiste già)
- Spese condivise e private scritte solo dal server; revisioni con
  approvazione, rimborsi, "segna come pagato", storico (B8.4-B8.7).
- Divisione: "Totale da dividere" in parti uguali oppure quote libere per
  persona (importi), controllate da CustomSplitValidator e dal server.
- Più valute con tasso bloccato per spesa; valuta di visualizzazione da
  Aspetto (1.46.0, fatto: punto "importi nella valuta di visualizzazione"
  già coperto).
- Budget personale privato (B7.1: `budgetPrivateOwners/{uid}/settings/
  personalBudget`, solo il proprietario).
- Cruscotto per categoria con ciambella e andamento nel tempo per giorno
  (viaggi fino a 45 giorni) o per mese (B8.5): il "grafico delle spese per
  giorno" esiste già.
- Totali per categoria e per persona in un modulo condiviso
  (budget_category_totals.dart, 1.56.0).
- Spesa collegata dalle sezioni (alloggi, trasporti, prenotazioni,
  ristoranti, shopping) con costo previsto nella sezione.

## Punti

| # | Punto | Cosa tocca | Rischi sui soldi | Lavoro |
|---|---|---|---|---|
| 1 | Budget previsto per categoria (gruppo) con avviso al superamento | nuova raccolta `budgetPlans` (per categoria: importo e valuta del viaggio), scritta solo dal server (nuova funzione `setBudgetPlan`, OWNER o tutti?) e letta dai membri; regole: sola lettura; app: barre "previsto / speso" nel cruscotto con i totali già calcolati | nessuno sui saldi (è solo un confronto); rischio di confusione se previsto e speso sono in valute diverse: il previsto si salva nella valuta del viaggio | medio |
| 2 | Budget previsto per persona | esiste il budget personale privato; per categoria personale: stesso documento `personalBudget` con una mappa per categoria (regole del documento da estendere) | nessuno | piccolo |
| 3 | Avviso al superamento | solo app: confronto tra previsto e totale convertito (stessi tassi del cruscotto); avviso nella pagina, nessuna notifica (decisione fissa) | un tasso mancante esclude spese dal totale: l'avviso deve dire "parziale" come il cruscotto | piccolo |
| 4 | Divisioni non uguali: percentuali e parti ("2 quote a Yato, 1 a Leo") | solo un nuovo modo di inserimento nel dialogo: percentuali e parti si trasformano in importi per persona **prima** dell'invio (come "Per persona" oggi), con l'arrotondamento dei centesimi già usato da EqualSplitCalculator (il resto al primo in ordine stabile); server invariato (riceve importi) | arrotondamenti: la somma deve tornare al centesimo; test di parità con casi dispari (100 € in 3 parti, 33,33 % ...) | medio |
| 5 | Debiti aperti visibili in home | la home del viaggio è "gestione viaggio" (approvata): un riquadro che usa BudgetDebtOverviewCalculator già esistente; vedi HOME-VIAGGIO.md | nessuno (lettura) | piccolo dopo la home |
| 6 | Categorie personalizzate e multiple nelle spese (componente D) | oggi `category` è un solo testo; più categorie = nuovo campo `categories` (elenco) accettato dalla funzione `createBudgetExpense` e dalle revisioni, regole di sola lettura invariate; totali: una spesa con 2 categorie va contata **una volta** nel totale e divisa o duplicata nelle categorie? Proposta: categoria principale (prima dell'elenco) per i totali, le altre solo come etichette e filtro | alto se si conta due volte: i totali per categoria non tornerebbero col totale generale; con la "principale" il rischio sparisce | medio-alto |
| 7 | Confronto preventivato e speso | il costo previsto è già nelle sezioni; l'importo speso è quello della spesa collegata: pagina o riquadro "Previsto / Speso" per sezione, solo lettura (Statistiche o cruscotto) | nessuno; attenzione alle valute (conversione con i tassi del budget) | piccolo |
| 8 | Grafico delle spese per giorno | già presente (B8.5): eventualmente solo vista "per giorno" anche oltre 45 giorni | nessuno | piccolissimo |
| 9 | Foto dello scontrino (dipende da Drive) | vedi sotto | nessuno sui saldi; rischio privacy | medio |

## Foto dello scontrino e Google Drive
Come nasce la cartella oggi: alla creazione del viaggio l'organizzatore
sceglie o crea una cartella nel **proprio** Google Drive
(GoogleDriveArchiveService: autorizzazione con l'accesso limitato ai file
creati dall'app, `drive.file`; `createFolder` dentro la cartella scelta);
il viaggio salva `cloudArchive` (id, nome, link della cartella). L'app non
condivide la cartella con gli altri membri e non ha permessi per farlo.

Proposta (nessun file su Firebase, come per i Ricordi):
- Chi allega: chi ha creato la spesa o chi l'ha pagata. Il file va nel
  **suo** Drive (accesso `drive.file`, nessun permesso in più), in una
  cartella "Amaterasu - <viaggio> - Scontrini" creata dall'app.
- Nella spesa si salva solo il link (il campo `link` esiste già dalla
  1.35.0; oppure un campo `receiptLink` dedicato, scritto dal server).
- Chi vede: la spesa condivisa la vedono i partecipanti, la privata solo
  il proprietario (regole attuali); il **file** lo vede solo chi ha accesso
  su Drive: chi allega può scegliere "condividi con chi ha il link" dal
  pannello di Drive. L'app lo dice chiaramente.
- Spese private: link visibile solo al proprietario (già garantito dalle
  regole).
- Cancellazione dell'account: i file restano nel Drive dell'utente (sono
  suoi); l'informativa va aggiornata.

## Ordine consigliato
1. Punto 8 (vista per giorno oltre 45 giorni) e 7 (previsto/speso):
   solo lettura, nessun rischio.
2. Punti 1-3 (budget previsto e avviso): nuova raccolta e funzione, nessun
   cambio ai calcoli esistenti.
3. Punto 4 (percentuali e parti): solo inserimento, server invariato,
   test di parità.
4. Punto 9 (scontrini su Drive): dopo l'ok sulla privacy.
5. Punto 6 (più categorie): ultimo, con la regola della categoria
   principale.
6. Punto 5 con la home del viaggio (HOME-VIAGGIO.md).
