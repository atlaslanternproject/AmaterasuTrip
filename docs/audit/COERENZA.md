# Tabella di coerenza dei moduli approvati

Scritta il 25/11/2026 (versione 1.57.0) confrontando
docs/audit/INVENTARIO-UI.md (scritto alla 1.23.0, aggiornato qui con lo
stato attuale) con docs/design/DIRETTIVE-UI.md. Riguarda solo l'**aspetto**
dei moduli approvati: bucket list, budget, gestione viaggio (home globale
e home del viaggio comprese), impostazioni, alloggi. **Nessuna** modifica a
funzioni, dati, regole o calcoli. Non sono differenze (restano come sono):
la copertina del viaggio e la foto del luogo in testa alle card.

Dopo il tuo ok: correzioni a gruppi (A, B, C… sotto), un commit per
gruppo, test di regressione dei moduli toccati, un rilascio per gruppo.

## Gruppo A - Spese (budget)
| # | Cosa | Dove | Proposta |
|---|---|---|---|
| A1 | "Originale: X" anche a parità di valuta | budget_shown_amount_text.dart | **Già risolto nella 1.46.0** (E7, con il tuo ok): nessuna azione |
| A2 | Riquadri "Ti devono 0" / "Devi restituire 0" sempre visibili anche a zero | budget_user_settlement_summary*.dart (budgetOthersOweYou, budgetYouOwe) | Un solo riquadro compatto "Sei in pari" quando entrambi sono 0; i due riquadri solo se uno è diverso da 0 |
| A3 | Selettori Gruppo/Personali ripetuti due volte (lista e cruscotto) | trip_expenses_page.dart:212 e budget_category_dashboard.dart:137 | Un solo selettore in alto nella pagina, che vale per lista e cruscotto |
| A4 | Nomi dei totali troppo simili ("La tua quota delle spese condivise", "Quota", "Spesa a tuo carico (pagata e da saldare)", totale del gruppo) | b6MyShare, btHistShare, btPersonalYourSharePaidAnd, b6GroupTotal | Tre nomi distinti e brevi: "Totale del gruppo", "La mia parte", "Ho pagato"; una riga di spiegazione al tocco |
| A5 | Ciambella con colori troppo simili tra categorie vicine | BudgetChartPalette (budget_charts.dart) | Tavolozza riordinata con contrasto maggiore tra vicini (stessi colori del tema, ordine diverso; più tonalità dagli accenti esistenti); legenda già presente |
| A6 | "Fonte e data dei cambi applicati" che si apre vuota quando non ci sono cambi | budget_category_dashboard_summary.dart:245 | Nasconderla quando non ci sono spese in altre valute |
| A7 | Icone in alto senza etichetta (4-5 nell'intestazione) | trip_expenses_page.dart, trip_expenses_export_button.dart | Etichetta sotto o accanto (schermo largo), suggerimento al tocco lungo; massimo 3 icone, le altre nel menu "⋮" |
| A8 | Dialogo sopra dialogo (dettagli → revisione/dichiara pagamento → conferma), fino a 3 livelli | budget_expense_details_dialog.dart e pannelli | Pannello dal basso su telefono / finestra su schermo largo con azioni sul posto; una sola conferma sopra |
| A9 | Pulsanti: Elimina/Annulla spesa a volte come testo rosso | dialoghi del budget | Quattro tipi delle direttive: principale arancio pieno, secondario a contorno, testo, distruttivo rosso con doppia conferma |
| A10 | "Modifica" dentro il dialogo dei dettagli, non come matita | budget_expense_details_dialog.dart | Matita in alto nel dettaglio, stessa posizione delle card |
| A11 | Filtri con pulsante e dialogo propri | budget_expense_filters / toolbar | Componente filtri condiviso (pulsante "Filtri" con conteggio, pannello, "Azzera filtri") |
| A12 | Colori scritti a mano (21) | file del budget (INVENTARIO 7) | Token di AmaterasuColors con gli stessi valori |
| A13 | Formato di data e ora di Aspetto non applicato | budget | AmaterasuDates come nelle sezioni nuove |
| A14 | Stati vuoti con solo testo | lista spese | Stato vuoto comune (icona in riquadro, testo, pulsante) |

## Gruppo B - Home globale (gestione viaggio)
| # | Cosa | Dove | Proposta |
|---|---|---|---|
| B1 | La home globale è la pagina di prova "Login completato!" con nome completo, email e UID | lib/features/home/presentation/pages/home_page.dart | Home vera: saluto con lo username, "I miei viaggi" (prossimo viaggio in evidenza con conto alla rovescia, poi gli altri), pulsante "Nuovo viaggio", accesso a Impostazioni; nessuna email né UID a schermo |

## Gruppo C - Home del viaggio (gestione viaggio)
| # | Cosa | Dove | Proposta |
|---|---|---|---|
| C1 | Tre voci in riquadri, spazio vuoto e barra inferiore che ripete le stesse voci | trip_overview_page.dart:106-124 e TripWorkspaceBottomBar | Home per fase (Prima, Durante, Dopo) come in docs/design/HOME-VIAGGIO.md; le voci della barra non si ripetono nella pagina |
| C2 | 27 colori scritti a mano | trip_overview_page_widgets.dart, *_hero_parts.dart | Token di AmaterasuColors |

## Gruppo D - Alloggi
| # | Cosa | Dove | Proposta |
|---|---|---|---|
| D1 | Cerca apre gli alloggi senza risalto dell'elemento trovato (le sezioni nuove lo fanno dalla 1.53.0) | pagina alloggi | Stesso segno condiviso (tripSectionFocusProvider): scorre fino all'alloggio e lo evidenzia 3 secondi (decisione del 25/11: nel giro finale) |
| D2 | Editor con 11 blocchi sempre aperti | editor degli alloggi | Editor a tendina con riga di riepilogo (componente delle sezioni nuove TripSectionBlock), "Salva" arancio fisso in basso |
| D3 | Al 130 % su telefono escono dallo spazio i titoli dei blocchi e la tendina "Prenotato su" | trip_stay_editor_section.dart:34, trip_stay_booking_section.dart:39 | Testo flessibile (risolto anche da D2) |
| D4 | Elimina con una sola conferma | conferma degli alloggi | Distruttivo rosso con doppia conferma (vale anche per le sezioni nuove: confirmTripSectionDelete) |
| D5 | Formato di data e ora di Aspetto non applicato | card ed editor | AmaterasuDates |

## Gruppo E - Bucket list
| # | Cosa | Dove | Proposta |
|---|---|---|---|
| E1 | "+" in basso (altrove in alto a destra) | pagina bucket list | Decidere un'unica posizione per tutta l'app (proposta: in alto a destra come le sezioni, oppure in basso ovunque) |
| E2 | "Modifica" come voce di menu e pulsante con testo | card della bucket list | Matita in alto nella card |
| E3 | Testi `_t(...)` non in l10n | file della bucket list | Spostarli in app_it.arb / app_en.arb (già TODO(audit)) |
| E4 | Copie proprie di link e luoghi | campo link e ricerca luoghi | Moduli comuni lib/core/links e lib/core/places (TODO(audit)) |
| E5 | Filtri e metodo con componenti propri | pagina bucket list | Componente filtri condiviso |
| E6 | Nomi dei votanti dai profili (da verificare caso per caso) | voti | Funzione condivisa dello username (regola 2) |
| E7 | 15 colori scritti a mano; non provata al 130 % | file della bucket list | Token; prova al 130 % |

## Gruppo F - Impostazioni (globali e del viaggio)
| # | Cosa | Dove | Proposta |
|---|---|---|---|
| F1 | Viaggiatori: nome completo con username sotto | impostazioni del viaggio > viaggiatori | Solo username (regola 2) |
| F2 | Conferme con AlertDialog e pulsanti di stili diversi (18 dialoghi) | impostazioni e impostazioni del viaggio | Popup secondo le direttive (pannello dal basso su telefono, principale + secondario, distruttivo con doppia conferma) |
| F3 | 28 colori scritti a mano (9 + 19) | amaterasu_settings_card.dart e pagine | Token |
| F4 | Formato di data e ora di Aspetto non applicato; non provate al 130 % | pagine delle impostazioni | AmaterasuDates; prova al 130 % |

## Gruppo G - In tutta l'app (componenti)
| # | Cosa | Proposta |
|---|---|---|
| G1 | Pulsante principale in tre forme (AmaterasuPrimaryButton, FilledButton arancio, ElevatedButton) | Un componente principale (alto 56 e variante compatta per i dialoghi), secondario e terziario come componenti |
| G2 | Pannello dal basso / finestra centrale chiamati in modi diversi | Un componente unico (telefono: dal basso con barra; largo: centrale) |
| G3 | Selettore valuta in due forme | Pillola + pannello del budget estratto e usato ovunque (TODO(audit) C7) |
| G4 | Stampe (budget, checklist, PDF del viaggio) con tre copie dello stesso stile | Modulo comune di stampa (TODO(audit) in trip_pdf_summary.dart) |
| G5 | Testi in it/en: controllare che i moduli approvati non abbiano testi scritti nel codice | check_l10n e ricerca dei testi |

Attendo il tuo ok (anche gruppo per gruppo) prima di cambiare l'aspetto
di questi moduli.
