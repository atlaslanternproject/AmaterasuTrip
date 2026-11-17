import 'package:flutter/widgets.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

/// Testi del budget nella lingua scelta dal flag `it` che le schermate
/// del budget si passano già (true = italiano, false = inglese).
AppLocalizations budgetL10n(bool it) =>
    lookupAppLocalizations(Locale(it ? 'it' : 'en'));
