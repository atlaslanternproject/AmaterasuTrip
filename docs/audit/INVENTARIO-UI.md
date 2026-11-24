# Inventario dell'interfaccia (Passo 1a, prompt v2)

Analisi in sola lettura del codice di `lib/` al 24/11/2026, versione
1.23.0. Conteggi ricavati con uno script che cerca i componenti Flutter
nei file: i numeri sono occorrenze nel codice, non schermate.
Nessun file dell'app è stato modificato.

## 1. Tabella per area

Legenda colonne: pulsanti pieni (Filled/Elevated), contorno (Outlined),
testo (Text), icona (Icon), menu "⋮" (PopupMenu), pulsante principale
condiviso (AmaterasuPrimaryButton), dialoghi (showDialog / AlertDialog),
pannelli dal basso (BottomSheet), selettori di data e ora, chip,
SegmentedButton, tendine (Dropdown), colori scritti a mano
(`Color(0x...)`) e `Colors.*`, uso di `displayName` / `username`.

| Area | Pieno | Elevated | Contorno | Testo | Icona | Menu | Primario | showDialog | Alert | Sheet | Data | Ora | Chip scelta | Chip filtro | Segmented | Tendina | Colori a mano | Colors.* | displayName | username |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| core/media | 1 | | | 1 | | | | 1 | 1 | | | | | | | | | | | |
| core/places | 1 | | | 2 | 2 | | | 1 | 1 | | | | | | | | 1 | | | |
| core/theme | | | | | | | | | | | | | | | | | 49 (token) | 2 | | |
| core/widgets | | 1 | | 4 | 1 | | 4 | 1 | 1 | | | | | | | | 12 | 8 | | |
| features/auth | | 3 | | 5 | | | 2 | | 1 | | | | | | | | | 10 | | 25 |
| features/home | | 1 | | | | | | | | | | | | | | | | | 1 | |
| features/profile | | | | | | | | | | | | | | | | | | | | 28 |
| features/settings | 6 | | 1 | 10 | 3 | | 2 | 8 | 8 | 1 | | | | | | | 9 | 2 | | 80 |
| trips/budget | 17 | | 9 | 28 | 2 | | | 13 | 14 | 4 | 2 | | | | | 6 | 21 | | 3 | 4 |
| trips/create_trip | 3 | | 1 | 3 | 4 | | | 2 | 2 | 2 | 2 | | | | | | 37 | 3 | 12 | |
| trips/trip_card | | | | | | | | | | | | | | | | | 13 | 11 | | |
| trips/trips_page | | | | | | | | | | | | | | | | | 5 | | | |
| trips/sections (modulo comune) | 3 | | 1 | 8 | 4 | 2 | | 5 | 2 | | 1 | 1 | 2 | 1 | 1 | 1 | | | 2 | |
| workspace/bucket_list | 7 | | 4 | 7 | 11 | | | 5 | 5 | 2 | | | | | 2 | 2 | 15 | 1 | 2 | |
| workspace/expenses | | | | | 5 | 1 | | 2 | | | | | | | | | | | | |
| workspace/more/hotels | 4 | | 3 | 12 | 6 | 2 | | 6 | 2 | 1 | 2 | 1 | 2 | 3 | 1 | 2 | 1 | | 1 | |
| workspace/more/notes | | | | 2 | 1 | | | | | | | | | | | | | | | |
| workspace/more/shopping | | | | | | | | | | | | | | | 1 | | | | | |
| workspace/more/transport | | | | | | | | | | | | | | | | 1 | | | | |
| workspace/overview | | | | | | | | | | | | | | | | | 27 | | | |
| workspace/settings | 13 | | 1 | 11 | 6 | 1 | | 10 | 10 | 2 | 2 | | | | 1 | | 19 | 5 | 9 | 8 |
| workspace/widgets | | | | | 2 | | | | | | | | | | | | 5 | | | |

Le altre sezioni nuove (Prenotazioni, Ristoranti, Luoghi salvati,
Ricordi) non compaiono perché usano solo il modulo comune
`lib/features/trips/sections`.

## 2. Pulsanti e varianti
- Principale: tre forme diverse. `AmaterasuPrimaryButton` (alto 56,
  accesso e impostazioni), `FilledButton` arancio `accentBudget`
  (budget, alloggi, sezioni nuove, impostazioni del viaggio),
  `ElevatedButton` (accesso, home globale).
- Secondario: `OutlinedButton` nel budget, negli alloggi (date) e nella
  bucket list; nelle sezioni nuove solo i pulsanti giorno.
- Terziario: `TextButton` ovunque per Annulla; colori diversi (crema,
  testo secondario, arancio).
- Distruttivo: `FilledButton` rosso `error` per Elimina negli alloggi e
  nelle sezioni nuove; nel budget e nelle impostazioni Elimina e
  Annulla spesa sono a volte `TextButton` rossi.
- "Modifica": matita in alto a destra nella card (alloggi e sezioni
  nuove, colore oro); nella bucket list voce del menu e pulsante nella
  card con testo; nel budget dentro il dialogo dei dettagli.
- "+": in alto a destra nell'intestazione (alloggi, sezioni nuove,
  spese come icona `add_circle_outline`), nella bucket list pulsante in
  basso.

## 3. Dialoghi, pannelli e sovrapposizioni
- `AlertDialog` per conferme (elimina, annulla, uscita senza salvare):
  budget 14, impostazioni del viaggio 10, impostazioni 8, bucket list 5.
- Dialoghi grandi: editor alloggi e sezioni (finestra centrale 640),
  creazione spesa del budget (dialogo a passi), dettagli spesa del
  budget con pannelli revisioni e rimborsi (dialogo sopra dialogo:
  dettagli → dichiara pagamento → conferma), storico del viaggio.
- Pannelli dal basso: valuta (budget, budget personale), filtri degli
  alloggi, metodo della bucket list, revisione cancellazione bucket,
  copertina, foto profilo, archivio Drive, viaggiatori, informazioni
  del viaggio.
- Sovrapposizioni: budget (dettagli → revisione → conferma) e bucket
  list (scheda → richiesta cancellazione → conferma) aprono fino a tre
  livelli.

## 4. Editor (campi e sezioni)
| Editor | Sezioni | Campi circa | Note |
|---|---|---|---|
| Alloggio | 11 blocchi sempre aperti | 30 | luogo Google, contatti, costo, servizi |
| Trasporto | 7 blocchi | 24 | fuso UTC a tendina |
| Prenotazione | 5 blocchi | 14 | |
| Ristorante | 5 blocchi | 14 | voti fuori dall'editor |
| Luogo salvato | 2 blocchi | 6 | link Maps |
| Nota | 2 blocchi | 5 + checklist | |
| Acquisto / Valigia | 2 / 1 blocchi | 9 / 3 | |
| Ricordo | 2 blocchi | 6 | |
| Spesa (budget) | dialogo a passi | 10-15 | pagatori, quote, metodi |
| Attività bucket list | pagina unica | 8 testi + chip | testi `_t(...)` non in l10n |
| Creazione viaggio | pagine a passi | destinazione, date, valuta, copertina, archivio | |
Nessun editor usa sezioni a tendina: tutti mostrano tutti i blocchi aperti.

## 5. Selettori
- Valuta: due forme. Budget: pillola con codice e pannello dal basso
  con ricerca (`budget_create_dialog_currency`, copiato in 3 file,
  TODO(audit) C7). Alloggi e sezioni nuove: tendina di codici.
- Data: `showDatePicker` standard ovunque, pulsanti con etichette
  diverse ("Giorno di check-in: …", "Giorno: …").
- Ora: `showTimePicker` standard; fuso orario solo nei trasporti
  (tendina "UTC+01:00").
- Luogo: `AmaterasuPlaceSearchField` (alloggi e sezioni nuove), ricerca
  propria nella bucket list e nella creazione del viaggio.
- Persone: chip filtro con il nome (alloggi, sezioni nuove), elenco con
  avatar nel budget (`BudgetTravelerTile`).
- Categoria: chip a scelta singola nelle sezioni, selettore con
  categorie personalizzate ("Altro") nella bucket list e nel budget.

## 6. Filtri, chip, stati vuoti, card, intestazioni
- Filtri: alloggi con un pulsante "Filtri" e pannello (il componente
  da tenere); budget con pulsante e dialogo propri; sezioni nuove con
  righe di chip impilate (fino a 4 righe nei trasporti: da correggere,
  tappa 1b); bucket list con metodo e filtri propri.
- Chip di stato: stesso disegno (pillola colorata) in alloggi e sezioni
  nuove; il budget usa testi colorati.
- Stati vuoti: icona in riquadro arancio + testo + pulsante (alloggi e
  sezioni nuove); budget e bucket list con testi semplici.
- Card: alloggi e sezioni nuove (bordo `borderAccent`, raggio 20, foto
  in testa); bucket list (stile da cui derivano); budget (righe per
  giorno); viaggi (`TripCard` con copertina).
- Intestazioni: sezioni di Altro con freccia, titolo 24 e "+"; budget
  con AppBar e 4-5 icone senza etichetta; home del viaggio con
  copertina.

## 7. Token di colore, testo e spazi
- Colori: `AmaterasuColors` (49 valori): background #1A0B08, primary
  #E5482E, success #3DBE6C, error #E25555, testi #F2E7D5 / #B7A99B /
  #9E9287, superfici #100C0A…#332824, bordi #3A2A20…#68402B, accenti
  #D96C32 (budget), #E28A32, #E3A66C, #E86A3A, #E17A43 e varianti.
- Spazi: `AmaterasuSpacing` 4, 8, 16, 24, 32, 48. Raggi:
  `AmaterasuRadius` 8, 14, 24 (nelle card però 12-20 scritti a mano).
- Testo: font di sistema, dimensioni scritte a mano (12, 13, 14, 15,
  16-18, 20-24); nessun token tipografico.
- Colori ancora scritti a mano: 37 in creazione viaggio, 27 nella
  panoramica del viaggio, 21 nel budget, 19 nelle impostazioni del
  viaggio, 15 nella bucket list, 13 in `TripCard`, 12 in
  `core/widgets`, 9 nelle impostazioni (vedi elenco file sotto).

File con più colori scritti a mano: trip_card.dart 13,
trip_created_page.dart 12, trip_cover_picker.dart 12,
trip_overview_page_widgets.dart 11, trip_overview_page_hero_parts.dart 9,
trip_traveller_profile_edit_page.dart 9,
trip_information_settings_page.dart 8, destination_result_card.dart 7,
amaterasu_settings_card.dart 6, bucket_activity_card_part.dart 6.

## 8. Come vengono mostrati i nomi delle persone
- Budget: `BudgetApi.travelers()` usa lo USERNAME per primo (poi nome
  e cognome): è la funzione corretta da riusare.
- Alloggi e sezioni nuove: `tripStaysMemberNamesProvider` usa
  `TripMember.displayName`, che dà NOME E COGNOME e solo in mancanza lo
  username (es. "Tommaso Dal Santo"): da correggere (tappa 1b).
- Impostazioni del viaggio (viaggiatori): nome completo con username
  sotto.
- Home globale: `user.displayName` (nome completo), più email e UID
  (pagina di prova "Login completato!").
- Bucket list: nome dai profili dei voti (da verificare caso per caso).

## 9. Componenti condivisi: cosa serve e cosa c'è già
1. Pulsante principale: esiste `AmaterasuPrimaryButton` (56 di altezza);
   serve una versione compatta per i dialoghi.
2. Pulsante secondario (contorno): non esiste come componente.
3. Pulsante terziario (testo): non esiste, colori diversi ovunque.
4. Pulsante distruttivo con doppia conferma: non esiste
   (`confirmTripSectionDelete` fa una sola conferma).
5. Pulsante "Modifica" a matita: esiste di fatto nelle card delle
   sezioni, non come componente.
6. Editor a tendina con riepilogo: non esiste; esiste
   `TripSectionEditorFrame` (cornice) da estendere.
7. Pannello dal basso / finestra centrale: non esiste un componente
   unico (ogni file chiama showModalBottomSheet o showDialog).
8. Selettore valuta: esiste nel budget (pillola + pannello), da estrarre
   e riusare ovunque.
9. Filtri: esiste negli alloggi (pulsante + pannello + Azzera), da
   estrarre in un modulo condiviso.
10. Nome persona: esiste la logica nel budget (username); manca una
    funzione condivisa per tutta l'app.
11. Link utili: esiste `lib/core/links` e il campo della bucket list
    (copia propria, TODO(audit)).
12. Luogo, foto, contatti: esiste `lib/core/places`.
13. Stato vuoto, card, chip di stato, viste Card/Elenco/Dettagli:
    esistono nel modulo `sections` (da usare anche per le future).
14. Categorie personalizzate: esistono nella bucket list ("Altro"), da
    estrarre senza cambiarla (tappa D).
15. Token tipografici: non esistono; le dimensioni sono scritte a mano.
