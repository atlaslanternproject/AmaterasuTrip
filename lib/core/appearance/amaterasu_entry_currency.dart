// Valuta di partenza delle nuove voci (Extra E6): quella scelta in
// Impostazioni > Aspetto, se c'è; altrimenti null e si usa la valuta di
// oggi (quella del viaggio). Cambia solo il valore iniziale del pulsante
// valuta: importi, cambi e calcoli restano quelli di sempre.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'amaterasu_appearance_provider.dart';

String? amaterasuDefaultEntryCurrency(BuildContext context) {
  try {
    return ProviderScope.containerOf(
      context,
      listen: false,
    ).read(amaterasuAppearanceProvider).defaultCurrency;
  } catch (_) {
    return null;
  }
}

/// Display currency of Settings > Appearance (it follows the default one
/// when not chosen); null = show the original currency.
String? amaterasuShownCurrency(BuildContext context) {
  try {
    return ProviderScope.containerOf(
      context,
      listen: false,
    ).read(amaterasuAppearanceProvider).shownCurrency;
  } catch (_) {
    return null;
  }
}
