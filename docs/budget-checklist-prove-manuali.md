# Budget: checklist delle prove manuali (B8.7)

Prove da fare a mano su **Web** e **Android** prima di considerare chiuso
il budget. Per ogni prova segna l'esito nelle due colonne.

## Prima di iniziare

- [ ] Le Cloud Functions nuove (`syncBudgetParticipantNames`,
      `closeBudgetDebt`, `listBudgetHistory`) e quelle modificate sono
      disponibili dove provi l'app. Senza deploy esistono solo negli
      emulatori: in produzione lo storico mostrerebbe un errore.
- [ ] Due account con email verificata: **Anna** (proprietaria) e
      **Bruno** (viaggiatore). Un terzo account **Carla** che non fa parte
      del viaggio.
- [ ] Un viaggio con valuta **EUR**, con Anna e Bruno come membri.
- [ ] Profili con nome compilato (username oppure nome e cognome).

Legenda: ✅ ok · ❌ problema (annota cosa vedi) · — non applicabile.

## 1. Creazione spesa

| # | Prova | Risultato atteso | Web | Android |
|---|---|---|---|---|
| 1.1 | Anna crea "Cena" 60,00 EUR, pagata da lei, divisa con Bruno | Compare nella lista; Bruno deve 30,00 EUR ad Anna | | |
| 1.2 | Anna crea una spesa con data effettiva di 3 giorni fa | Nella lista e nei filtri conta la data scelta, non oggi | | |
| 1.3 | Anna crea una spesa "pianificata" | Non crea debiti; il pannello rimborsi dice che i debiti diventano definitivi solo dopo il pagamento | | |
| 1.4 | Anna crea una spesa privata | Bruno non la vede da nessuna parte (lista, grafici, storico) | | |
| 1.5 | Spesa con due metodi di pagamento (carta + contanti) | Il dettaglio mostra entrambi con gli importi | | |
| 1.6 | Importo zero o quote che non tornano | Il salvataggio è bloccato con un messaggio chiaro | | |

## 2. Modifica e approvazione

| # | Prova | Risultato atteso | Web | Android |
|---|---|---|---|---|
| 2.1 | Anna propone di cambiare l'importo di "Cena" | La modifica resta in attesa finché Bruno non approva | | |
| 2.2 | Bruno approva | La spesa passa alla versione 2; nello storico compare "ha applicato la modifica n. 2" | | |
| 2.3 | Bruno rifiuta un'altra proposta | La spesa resta com'era | | |
| 2.4 | Anna chiede di annullare una spesa, Bruno rifiuta, Anna richiede, Bruno approva | La spesa risulta annullata; lo storico mostra tutti i passaggi, compreso il primo rifiuto | | |

## 3. Rimborsi

| # | Prova | Risultato atteso | Web | Android |
|---|---|---|---|---|
| 3.1 | Bruno segnala un rimborso di 10,00 EUR ad Anna con bonifico | Compare "In attesa di conferma" per Anna | | |
| 3.2 | Anna conferma | Il debito scende a 20,00 EUR; storico: richiesta + conferma | | |
| 3.3 | Bruno segnala 5,00 EUR, Anna rifiuta | Il debito resta 20,00 EUR; storico: rifiuto | | |
| 3.4 | Bruno prova a rimborsare più del dovuto | Il pulsante resta disattivato o compare un errore | | |
| 3.5 | Dopo un rimborso confermato, Anna prova a modificare gli importi della spesa | Bloccato: servono correzioni separate | | |

## 4. Valute e cambi

| # | Prova | Risultato atteso | Web | Android |
|---|---|---|---|---|
| 4.1 | Anna crea una spesa da 1000 JPY con data passata | Accanto all'importo compare il convertito in EUR con fonte e data del tasso | | |
| 4.2 | Stessa spesa senza connessione al momento della creazione | La spesa viene salvata lo stesso; dashboard e grafici la escludono e lo dicono | | |
| 4.3 | Anna corregge a mano il tasso con un motivo | Compare "Manuale"; nello storico c'è la correzione con il motivo | | |
| 4.4 | Bruno prova a correggere il tasso di una spesa di Anna | Non è permesso | | |
| 4.5 | Cambio della valuta di riepilogo dalla barra in alto | Totali e grafici si aggiornano; i debiti restano nella valuta originale | | |

## 5. Ex membro

| # | Prova | Risultato atteso | Web | Android |
|---|---|---|---|---|
| 5.1 | Con Bruno ancora nel viaggio, Anna apre la pagina Spese | Nessun cambiamento visibile (i nomi vengono salvati nelle spese in background) | | |
| 5.2 | Anna rimuove Bruno dal viaggio | Nelle spese e nei saldi Bruno compare ancora **per nome**, mai con un codice | | |
| 5.3 | Debito di Bruno verso Anna | Visibile, con "Ex viaggiatore: debito in sola lettura"; nessun pulsante di rimborso | | |
| 5.4 | Anna preme "Chiudi debito" senza motivo | Il pulsante di conferma resta disattivato | | |
| 5.5 | Anna chiude il debito con un motivo | Il residuo va a zero; compaiono "Chiuso (ex viaggiatore)", chi l'ha chiuso e il motivo; il debito originale resta nello storico | | |
| 5.6 | Bruno (ex membro) prova ad aprire il viaggio | Non vede spese, saldi né storico | | |
| 5.7 | Spesa creata **prima** di questo aggiornamento con un ex membro | Dopo l'apertura della pagina da parte di un membro, il nome compare; se il profilo non esiste più, compare "Ex viaggiatore" | | |

## 6. Budget personale

| # | Prova | Risultato atteso | Web | Android |
|---|---|---|---|---|
| 6.1 | Anna imposta un budget di 200,00 EUR | Compare "Budget previsto" e "Disponibile" | | |
| 6.2 | Spese pagate e da saldare | Conta solo la quota di Anna; le spese pianificate e annullate non contano | | |
| 6.3 | Superamento del budget | Compare "Oltre il budget" | | |
| 6.4 | Spesa in valuta senza tasso | "Rimanente non determinabile" invece di un numero inventato | | |
| 6.5 | Bruno non vede il budget di Anna | Il budget personale è privato | | |

## 7. Dashboard, grafici, filtri e storico

| # | Prova | Risultato atteso | Web | Android |
|---|---|---|---|---|
| 7.1 | Scheda "Spese del gruppo" | Ciambella per categoria e barre nel tempo; i colori dell'elenco corrispondono alla ciambella | | |
| 7.2 | Scheda "Le mie spese personali" | Solo spese private: niente spese del gruppo nei grafici | | |
| 7.3 | Filtro per categoria o periodo | Lista, totali e grafici mostrano le stesse spese | | |
| 7.4 | Viaggio lungo più di 45 giorni | L'andamento passa a "Totale per mese" | | |
| 7.5 | Tocco su una barra | Compare data e importo | | |
| 7.6 | Pulsante "Storico del viaggio" in alto | Elenco delle operazioni con nomi, titoli delle spese, "Privata" sulle proprie spese private | | |
| 7.7 | Carla (non membro) | Non può vedere lo storico | | |

## 8. Schermi e dispositivi

| # | Prova | Risultato atteso | Web | Android |
|---|---|---|---|---|
| 8.1 | Telefono piccolo (circa 360 px di larghezza) | Niente testo tagliato o strisce gialle e nere; tutto raggiungibile scorrendo | | |
| 8.2 | Browser largo (oltre 900 px) | Budget personale e saldi affiancati | | |
| 8.3 | Ridimensionamento della finestra del browser | Il layout si adatta senza errori | | |
| 8.4 | App in inglese | Tutti i testi nuovi sono tradotti | | |
| 8.5 | Rotazione dello schermo su Android | Nessun dato perso, nessun errore | | |

## Note

Annota qui i problemi trovati, con dispositivo, browser e passaggi per
riprodurli.
