# Tema chiaro: impatti (Extra E8, solo analisi)

Data: 25/11/2026. Nessun codice scritto: oggi l'app ha solo il tema scuro
(decisione fissa n. 5 di CLAUDE.md). Qui c'è cosa servirebbe per un tema
chiaro futuro, per decidere se e quando farlo.

## Stato attuale (contato nel codice)
- `lib/core/theme/app_theme.dart`: un solo tema, `brightness: dark`.
- `AmaterasuColors`: 51 colori fissi (costanti), pensati per lo sfondo
  scuro (testi crema, sfondi nero-bruno, bordi bruni).
- Colori scritti a mano fuori dal tema (`Color(0x...)`): 150, soprattutto
  in panoramica del viaggio (22), budget (18), bucket list (circa 15),
  viaggiatori nelle impostazioni del viaggio (10), impostazioni globali
  (9), componenti comuni in `lib/core/widgets` (12).
- `Colors.white` / `Colors.black` usati direttamente: 40 punti (ombre,
  sfondi delle foto, il riquadro bianco del biglietto QR...).
- Le sezioni nuove usano quasi solo i token (1 colore a mano).

## Cosa servirebbe
1. Token a due valori: ogni colore di `AmaterasuColors` con una versione
   chiara e una scura (es. un `ThemeExtension` letto con
   `Theme.of(context)`), perché oggi sono costanti e non possono cambiare
   con il tema. È il lavoro più grande: ogni uso `AmaterasuColors.x`
   dentro un `const` va riscritto.
2. Togliere i 150 colori a mano: diventano token (regola già scritta in
   CLAUDE.md: i colori usati 3 volte sono token). Nei moduli approvati
   (budget, bucket list, gestione viaggio, impostazioni) solo dopo l'ok su
   COERENZA.md, perché cambia l'aspetto.
3. Contrasto: i toni caldi (arancio #E5482E, oro #E3A66C) su bianco vanno
   ricontrollati per la leggibilità (alcuni oro/crema su fondo chiaro non
   bastano); servirebbero varianti più scure per il testo.
4. Foto e copertine: restano uguali; i testi sopra le foto usano già
   sfumature scure, da mantenere anche nel tema chiaro.
5. Grafici del budget (ciambella): colori delle categorie da ricontrollare
   su fondo chiaro.
6. Mappe Google: lo stile della mappa andrebbe abbinato al tema.
7. Pagine statiche in `hosting/` (invito, cancellazione dati): hanno un
   loro CSS scuro; andrebbero aggiornate a parte.
8. Scelta in Impostazioni > Aspetto ("Scuro / Chiaro / Come il sistema"),
   salvata con le altre preferenze (il campo `appearance` del profilo
   andrebbe esteso, con regole e test).

## Stima e ordine consigliato
- Prima: token a due valori e componenti comuni (`lib/core`), poi le
  sezioni nuove (già quasi tutte a token): poco rischio.
- Poi: i moduli approvati, uno alla volta, dopo COERENZA.md.
- Rischio principale: colori dimenticati che rendono testo invisibile
  (chiaro su chiaro). Servirebbero test che aprono ogni pagina in tutti e
  due i temi e controllano il contrasto dei testi principali.
- Costi: nessuna API e nessun costo in più.
