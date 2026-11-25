// Righe della card di un alloggio per le aggiunte facoltative v2: arrivo
// tardivo con la reception, accesso (codice della porta, Wi-Fi,
// istruzioni) e tassa di soggiorno totale (a persona per notte × notti ×
// persone). Compaiono solo se compilate.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/budget/calculations/budget_money_formatter.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

List<(IconData, String, Key)> tripStayExtrasLines(
  TripStay stay,
  AppLocalizations l10n,
) {
  final e = stay.extras;
  final late = e.lateArrivalTime;
  final reception = e.receptionContact;
  final wifi = [?e.wifiName, ?e.wifiPassword].join(' · ');
  final persons = e.taxPersons ?? stay.guestUids.length;
  final total = e.taxTotal(stay.nights, persons);
  final tax = e.taxMinorUnits;
  final currency = e.taxCurrency;
  return [
    if (late != null || reception != null)
      (
        Icons.nightlight_outlined,
        [
          if (late != null) l10n.staysLateArrivalValue(late),
          if (reception != null) l10n.staysReceptionValue(reception),
        ].join(' · '),
        const Key('stay-late-line'),
      ),
    if (e.doorCode case final code?)
      (
        Icons.vpn_key_outlined,
        l10n.staysDoorCodeValue(code),
        const Key('stay-door-line'),
      ),
    if (wifi.isNotEmpty)
      (
        Icons.wifi_rounded,
        l10n.staysWifiValue(wifi),
        const Key('stay-wifi-line'),
      ),
    if (e.accessNotes case final notes?)
      (Icons.info_outline_rounded, notes, const Key('stay-access-line')),
    if (tax != null && currency != null)
      (
        Icons.account_balance_outlined,
        total == null
            ? l10n.staysCityTaxEach(BudgetMoneyFormatter.format(tax, currency))
            : l10n.staysCityTaxValue(
                BudgetMoneyFormatter.format(total, currency),
                BudgetMoneyFormatter.format(tax, currency),
                stay.nights,
                persons,
              ),
        const Key('stay-tax-line'),
      ),
  ];
}
