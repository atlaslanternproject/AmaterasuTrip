// Pagina "Aspetto" delle Impostazioni globali (Extra E2): dimensione del
// testo, unità, formato data e ora, valuta predefinita per le nuove voci e
// valuta di visualizzazione. Ogni scelta si salva subito (dispositivo e
// profilo); gli importi originali non cambiano mai.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_appearance.dart';
import 'package:amaterasutrip/core/appearance/amaterasu_appearance_provider.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'appearance_currency_row.dart';

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    AmaterasuAppearance value,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context)!.appearanceSaveFailed;
    final ok = await ref
        .read(amaterasuAppearanceProvider.notifier)
        .update(value);
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(failed)));
  }

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: AmaterasuColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final a = ref.watch(amaterasuAppearanceProvider);
    void set(AmaterasuAppearance v) => _set(context, ref, v);
    Widget choices<T extends Object>(
      String key,
      List<T> values,
      String Function(T) label,
      T selected,
      AmaterasuAppearance Function(T) apply,
    ) => TripSectionChoices<T>(
      keyPrefix: 'appearance-$key',
      values: values,
      codeOf: (v) => '$v',
      labelOf: label,
      selected: selected,
      onChanged: (v) {
        if (v != null) set(apply(v));
      },
    );

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
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _title(l10n.appearanceTextSize),
          choices<int>(
            'text',
            AmaterasuAppearance.textScales,
            (v) => '$v%',
            a.textScale,
            (v) => a.copyWith(textScale: v),
          ),
          _title(l10n.appearanceUnits),
          choices<String>(
            'units',
            AmaterasuAppearance.unitsValues,
            (v) => v == 'km' ? l10n.appearanceUnitsKm : l10n.appearanceUnitsMi,
            a.units,
            (v) => a.copyWith(units: v),
          ),
          _title(l10n.appearanceDateFormat),
          choices<String>(
            'date',
            AmaterasuAppearance.dateFormats,
            (v) => switch (v) {
              'dmy' => l10n.appearanceDateDmy,
              'ymd' => l10n.appearanceDateYmd,
              _ => l10n.appearanceDateLocale,
            },
            a.dateFormat,
            (v) => a.copyWith(dateFormat: v),
          ),
          _title(l10n.appearanceTimeFormat),
          choices<String>(
            'time',
            AmaterasuAppearance.timeFormats,
            (v) => v == '24' ? l10n.appearanceTime24 : l10n.appearanceTime12,
            a.timeFormat,
            (v) => a.copyWith(timeFormat: v),
          ),
          _title(l10n.appearanceCurrencies),
          AppearanceCurrencyRow(
            keyPrefix: 'appearance-default-currency',
            label: l10n.appearanceDefaultCurrency,
            value: a.defaultCurrency,
            emptyText: l10n.appearanceCurrencyTrip,
            onChanged: (c) => set(
              c == null
                  ? a.copyWith(clearDefaultCurrency: true)
                  : a.copyWith(defaultCurrency: c),
            ),
          ),
          const SizedBox(height: 10),
          AppearanceCurrencyRow(
            keyPrefix: 'appearance-display-currency',
            label: l10n.appearanceDisplayCurrency,
            value: a.displayCurrency,
            emptyText: a.defaultCurrency == null
                ? l10n.appearanceDisplayOriginal
                : l10n.appearanceDisplayFollows(a.defaultCurrency!),
            onChanged: (c) => set(
              c == null
                  ? a.copyWith(clearDisplayCurrency: true)
                  : a.copyWith(displayCurrency: c),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.appearanceOriginalsUnchanged,
            style: const TextStyle(
              color: AmaterasuColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
