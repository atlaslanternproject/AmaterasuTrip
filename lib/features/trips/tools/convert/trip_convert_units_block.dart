// Blocchi "Unità" e "Taglie" di Converti: temperatura, distanze e pesi in
// entrambi i versi (scelta a pulsanti come nelle sezioni) e la tabella
// indicativa delle taglie delle scarpe EU/UK/US.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_convert_math.dart';

typedef _Unit = (String code, String from, String to, double Function(double));

class TripConvertUnitsBlock extends StatefulWidget {
  const TripConvertUnitsBlock({super.key});

  @override
  State<TripConvertUnitsBlock> createState() => _TripConvertUnitsBlockState();
}

class _TripConvertUnitsBlockState extends State<TripConvertUnitsBlock> {
  static const List<_Unit> _units = [
    ('c-f', '°C', '°F', TripConvertMath.celsiusToFahrenheit),
    ('f-c', '°F', '°C', TripConvertMath.fahrenheitToCelsius),
    ('km-mi', 'km', 'mi', TripConvertMath.kmToMiles),
    ('mi-km', 'mi', 'km', TripConvertMath.milesToKm),
    ('kg-lb', 'kg', 'lb', TripConvertMath.kgToPounds),
    ('lb-kg', 'lb', 'kg', TripConvertMath.poundsToKg),
  ];

  final _value = TextEditingController(text: '20');
  _Unit _unit = _units.first;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = TripConvertMath.parse(_value.text);
    final result = value == null
        ? '—'
        : '${TripConvertMath.show(value)} ${_unit.$2} = '
              '${TripConvertMath.show(_unit.$4(value))} ${_unit.$3}';
    return TripSectionBlock(
      title: l10n.convertUnits,
      icon: Icons.straighten_rounded,
      initiallyOpen: false,
      children: [
        TripSectionChoices<_Unit>(
          keyPrefix: 'convert-unit',
          values: _units,
          codeOf: (u) => u.$1,
          labelOf: (u) => '${u.$2} → ${u.$3}',
          selected: _unit,
          onChanged: (u) => setState(() => _unit = u ?? _unit),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('convert-unit-value'),
          controller: _value,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.convertValue),
        ),
        const SizedBox(height: 8),
        Text(
          result,
          key: const Key('convert-unit-result'),
          style: const TextStyle(
            color: AmaterasuColors.accentGold,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class TripConvertSizesBlock extends StatelessWidget {
  const TripConvertSizesBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String n(num v) => TripConvertMath.show(v.toDouble());
    TableRow row(List<String> cells, {bool head = false}) => TableRow(
      children: [
        for (final c in cells)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              c,
              style: TextStyle(
                color: head
                    ? AmaterasuColors.textCream
                    : AmaterasuColors.textPrimary,
                fontWeight: head ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
      ],
    );
    return TripSectionBlock(
      title: l10n.convertShoeSizes,
      icon: Icons.ice_skating_outlined,
      initiallyOpen: false,
      children: [
        Table(
          key: const Key('convert-sizes'),
          children: [
            row([
              'EU',
              'UK',
              l10n.convertUsMen,
              l10n.convertUsWomen,
            ], head: true),
            for (final s in TripConvertMath.shoes)
              row([n(s.eu), n(s.uk), n(s.usMen), n(s.usWomen)]),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.convertSizesNote,
          style: const TextStyle(
            color: AmaterasuColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
