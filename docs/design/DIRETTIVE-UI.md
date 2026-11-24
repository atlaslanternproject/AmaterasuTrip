# Direttive grafiche (prompt v2)

Valgono per ogni nuova schermata e, dopo l'ok sulla tabella
docs/audit/COERENZA.md, per i moduli approvati. Colori, font e icone
restano quelli attuali (lib/core/theme): i mockup di altre app servono
solo per la struttura, mai per colori, immagini o aspetto. Solo tema
scuro.

## Editor
- Un solo componente per tutti gli editor: sezioni a tendina con icona,
  titolo e freccia; da chiusa ogni sezione mostra una riga di riepilogo
  (es. "13 ago 15:35 → 14 ago 17:35").
- In creazione è aperta solo la sezione essenziale; in modifica restano
  chiuse e si apre quella toccata.
- "Salva" pieno arancio sempre visibile in basso; "Annulla" testuale.
- Un errore apre la sezione che lo contiene e la porta in vista.

## Popup
- Telefono: pannello dal basso con barra di trascinamento. Schermo
  largo: finestra centrale.
- Struttura: icona facoltativa, titolo, testo breve, un pulsante
  principale e uno secondario.
- Azioni distruttive in rosso e con DOPPIA conferma.
- Evitare popup sopra popup: preferire la modifica sul posto.

## Pulsanti (quattro tipi in tutta l'app)
- Principale: pieno arancio.
- Secondario: contorno.
- Terziario: solo testo.
- Distruttivo: rosso, solo per eliminare.
- Il "+" per aggiungere: da valutare in tabella se spostarlo in basso.

## Modifica
- Icona matita in alto nella card, sempre nello stesso punto; su
  schermo largo con la parola "Modifica".

## Card
- La foto del luogo in testa alla card RESTA com'è (carosello al tocco,
  vedi tappa 1b punto 7). Nessun banner decorativo; illustrazioni solo
  negli stati vuoti, piccole.
- Icona diversa per ogni sezione, stesso colore di accento.

## Link
- Sempre il modulo lib/core/links/ con il campo "Link utili" della
  bucket list (icona, "Aggiungi un link", rimuovi).

## Crea spesa
- Tipo di spesa a scelta, selettore "Totale / Per persona",
  partecipanti a selezione multipla con lo username accanto alla spunta
  e pulsante "Tutti".

## Filtri
- Resta il componente degli alloggi (un pulsante "Filtri" con conteggio,
  pannello, "Azzera filtri"), uguale in tutte le sezioni.

## Checklist
- Categorie a tendina, ognuna con barra di avanzamento e spunte in
  linea; pulsante "+" per aggiungere.

## Nomi
- Sempre lo username, mai nome completo né iniziali.

## Home del viaggio per fase (piano in docs/design/HOME-VIAGGIO.md)
- Fase scelta dalle date: Prima, Durante, Dopo; dashboard sotto la
  copertina.
- Prima: riquadro numerico con conto alla rovescia (icona sole, nessuna
  illustrazione), prontezza voce per voce, prossime scadenze, meteo,
  spese finora, checklist valigia, debiti aperti.
- Durante: "Oggi" in ordine di orario, prossimo evento, meteo, ora
  locale, spese di oggi, numeri di emergenza, pulsanti rapidi (aggiungi
  spesa).
- Dopo: statistiche (tre numeri, ciambella delle spese per categoria),
  conti da saldare, link ai ricordi, PDF.
- Nessun tema legato alla destinazione.
