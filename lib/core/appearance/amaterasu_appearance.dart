// Preferenze "Aspetto" dell'utente (Extra E): dimensione del testo, unità,
// formato data e ora, valuta predefinita per le nuove voci e valuta di
// visualizzazione. Solo scelte di visualizzazione: nessun importo o
// calcolo dipende da qui. Salvate nel profilo (viaggiatori/{uid}).

class AmaterasuAppearance {
  const AmaterasuAppearance({
    this.textScale = 100,
    this.units = 'km',
    this.dateFormat = 'locale',
    this.timeFormat = '24',
    this.defaultCurrency,
    this.displayCurrency,
  });

  static const textScales = [100, 110, 120, 130];
  static const unitsValues = ['km', 'mi'];
  static const dateFormats = ['locale', 'dmy', 'ymd'];
  static const timeFormats = ['24', '12'];
  static final _currency = RegExp(r'^[A-Z]{3}$');

  /// Percent of the normal text size.
  final int textScale;
  final String units;
  final String dateFormat;
  final String timeFormat;

  /// Starting currency of new entries; null = the trip currency.
  final String? defaultCurrency;

  /// Currency to show amounts in; null = follows [defaultCurrency], and
  /// without it the original currency is shown.
  final String? displayCurrency;

  /// Display currency actually used (falls back to the default one).
  String? get shownCurrency => displayCurrency ?? defaultCurrency;

  AmaterasuAppearance copyWith({
    int? textScale,
    String? units,
    String? dateFormat,
    String? timeFormat,
    String? defaultCurrency,
    bool clearDefaultCurrency = false,
    String? displayCurrency,
    bool clearDisplayCurrency = false,
  }) => AmaterasuAppearance(
    textScale: textScale ?? this.textScale,
    units: units ?? this.units,
    dateFormat: dateFormat ?? this.dateFormat,
    timeFormat: timeFormat ?? this.timeFormat,
    defaultCurrency: clearDefaultCurrency
        ? null
        : (defaultCurrency ?? this.defaultCurrency),
    displayCurrency: clearDisplayCurrency
        ? null
        : (displayCurrency ?? this.displayCurrency),
  );

  /// Saved map: only the values that differ from the defaults.
  Map<String, dynamic> toMap() => {
    if (textScale != 100) 'textScale': textScale,
    if (units != 'km') 'units': units,
    if (dateFormat != 'locale') 'dateFormat': dateFormat,
    if (timeFormat != '24') 'timeFormat': timeFormat,
    'defaultCurrency': ?defaultCurrency,
    'displayCurrency': ?displayCurrency,
  };

  /// Reads a saved map; unknown values fall back to the defaults.
  static AmaterasuAppearance fromMap(Object? raw) {
    if (raw is! Map) return const AmaterasuAppearance();
    T pick<T>(String key, List<T> allowed, T fallback) {
      final value = raw[key];
      return value is T && allowed.contains(value) ? value : fallback;
    }

    String? currency(String key) {
      final value = raw[key];
      return value is String && _currency.hasMatch(value) ? value : null;
    }

    return AmaterasuAppearance(
      textScale: pick<int>('textScale', textScales, 100),
      units: pick<String>('units', unitsValues, 'km'),
      dateFormat: pick<String>('dateFormat', dateFormats, 'locale'),
      timeFormat: pick<String>('timeFormat', timeFormats, '24'),
      defaultCurrency: currency('defaultCurrency'),
      displayCurrency: currency('displayCurrency'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AmaterasuAppearance &&
      other.textScale == textScale &&
      other.units == units &&
      other.dateFormat == dateFormat &&
      other.timeFormat == timeFormat &&
      other.defaultCurrency == defaultCurrency &&
      other.displayCurrency == displayCurrency;

  @override
  int get hashCode => Object.hash(
    textScale,
    units,
    dateFormat,
    timeFormat,
    defaultCurrency,
    displayCurrency,
  );
}
