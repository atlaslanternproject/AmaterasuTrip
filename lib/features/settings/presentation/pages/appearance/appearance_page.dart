// Pagina "Aspetto" delle Impostazioni globali sul modello della pagina
// Privacy (COERENZA F): frase introduttiva e card espandibili con icona,
// titolo e scelta attuale (Testo, Unità, Data e ora, Valute). Ogni scelta
// si salva subito (dispositivo e profilo); gli importi non cambiano mai.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_appearance.dart';
import 'package:amaterasutrip/core/appearance/amaterasu_appearance_provider.dart';
import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/settings/amaterasu_settings_card.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'appearance_currency_row.dart';

part 'appearance_page_cards.dart';

class AppearancePage extends ConsumerStatefulWidget {
  const AppearancePage({super.key});

  @override
  ConsumerState<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends ConsumerState<AppearancePage> {
  final _open = <String>{};

  Future<void> _set(AmaterasuAppearance value) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context)!.appearanceSaveFailed;
    final ok = await ref
        .read(amaterasuAppearanceProvider.notifier)
        .update(value);
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(failed)));
  }

  Widget _card(
    String id,
    IconData icon,
    String title,
    String subtitle,
    List<Widget> children,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: AmaterasuSettingsCard(
      key: Key('appearance-card-$id'),
      icon: icon,
      title: title,
      subtitle: subtitle,
      isExpanded: _open.contains(id),
      onTap: () =>
          setState(() => _open.contains(id) ? _open.remove(id) : _open.add(id)),
      children: children,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = ref.watch(amaterasuAppearanceProvider);
    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      appBar: AppBar(
        backgroundColor: AmaterasuColors.surfaceDeep,
        elevation: 0,
        title: Text(
          l10n.settingsAppearance,
          style: const TextStyle(
            color: AmaterasuColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        key: const Key('appearance-page'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            l10n.appearanceIntro,
            style: const TextStyle(
              color: AmaterasuColors.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _card(
            'text',
            Icons.format_size_rounded,
            l10n.appearanceTextSize,
            '${a.textScale}%',
            [_textChoices(l10n, a)],
          ),
          _card(
            'units',
            Icons.straighten_rounded,
            l10n.appearanceUnits,
            _unitLabel(l10n, a.units),
            [_unitChoices(l10n, a)],
          ),
          _card(
            'datetime',
            Icons.schedule_rounded,
            l10n.appearanceDateTime,
            '${_dateLabel(l10n, a.dateFormat)} · '
                '${_timeLabel(l10n, a.timeFormat)}',
            _dateTimeChoices(l10n, a),
          ),
          _card(
            'currencies',
            Icons.currency_exchange_rounded,
            l10n.appearanceCurrencies,
            l10n.appearanceCurrenciesSummary(
              a.defaultCurrency ?? l10n.appearanceCurrencyTrip,
              a.displayCurrency ??
                  a.defaultCurrency ??
                  l10n.appearanceDisplayOriginal,
            ),
            _currencyRows(l10n, a),
          ),
        ],
      ),
    );
  }
}
