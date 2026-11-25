// Parte di appearance_page.dart: il contenuto delle card di Aspetto
// (scelte a chip comuni delle sezioni e righe delle valute) e i nomi delle
// scelte attuali mostrati come descrizione delle card. Stesse scelte e
// stesse chiavi della pagina precedente.

part of 'appearance_page.dart';

extension _AppearanceCards on _AppearancePageState {
  Widget _choices<T extends Object>(
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
      if (v != null) _set(apply(v));
    },
  );

  String _unitLabel(AppLocalizations l10n, String v) =>
      v == 'km' ? l10n.appearanceUnitsKm : l10n.appearanceUnitsMi;

  String _dateLabel(AppLocalizations l10n, String v) => switch (v) {
    'dmy' => l10n.appearanceDateDmy,
    'ymd' => l10n.appearanceDateYmd,
    _ => l10n.appearanceDateLocale,
  };

  String _timeLabel(AppLocalizations l10n, String v) =>
      v == '24' ? l10n.appearanceTime24 : l10n.appearanceTime12;

  Widget _textChoices(AppLocalizations l10n, AmaterasuAppearance a) =>
      _choices<int>(
        'text',
        AmaterasuAppearance.textScales,
        (v) => '$v%',
        a.textScale,
        (v) => a.copyWith(textScale: v),
      );

  Widget _unitChoices(AppLocalizations l10n, AmaterasuAppearance a) =>
      _choices<String>(
        'units',
        AmaterasuAppearance.unitsValues,
        (v) => _unitLabel(l10n, v),
        a.units,
        (v) => a.copyWith(units: v),
      );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 6),
    child: Text(
      text,
      style: const TextStyle(color: AmaterasuColors.textSecondary),
    ),
  );

  List<Widget> _dateTimeChoices(AppLocalizations l10n, AmaterasuAppearance a) =>
      [
        _label(l10n.appearanceDateFormat),
        _choices<String>(
          'date',
          AmaterasuAppearance.dateFormats,
          (v) => _dateLabel(l10n, v),
          a.dateFormat,
          (v) => a.copyWith(dateFormat: v),
        ),
        const SizedBox(height: 10),
        _label(l10n.appearanceTimeFormat),
        _choices<String>(
          'time',
          AmaterasuAppearance.timeFormats,
          (v) => _timeLabel(l10n, v),
          a.timeFormat,
          (v) => a.copyWith(timeFormat: v),
        ),
      ];

  List<Widget> _currencyRows(AppLocalizations l10n, AmaterasuAppearance a) => [
    AppearanceCurrencyRow(
      keyPrefix: 'appearance-default-currency',
      label: l10n.appearanceDefaultCurrency,
      value: a.defaultCurrency,
      emptyText: l10n.appearanceCurrencyTrip,
      onChanged: (c) => _set(
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
      onChanged: (c) => _set(
        c == null
            ? a.copyWith(clearDisplayCurrency: true)
            : a.copyWith(displayCurrency: c),
      ),
    ),
    const SizedBox(height: 10),
    Text(
      l10n.appearanceOriginalsUnchanged,
      style: const TextStyle(color: AmaterasuColors.textMuted, fontSize: 13),
    ),
  ];
}
