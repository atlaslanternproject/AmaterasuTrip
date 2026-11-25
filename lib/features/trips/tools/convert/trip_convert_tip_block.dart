// Blocco "Mancia" di Converti: conto, percentuale (0-20 %) e persone;
// mostra mancia, totale e quota a testa nella valuta del viaggio. Solo un
// calcolo: non crea spese.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_convert_math.dart';

class TripConvertTipBlock extends StatefulWidget {
  const TripConvertTipBlock({super.key, required this.currency});

  final String currency;

  @override
  State<TripConvertTipBlock> createState() => _TripConvertTipBlockState();
}

class _TripConvertTipBlockState extends State<TripConvertTipBlock> {
  final _bill = TextEditingController(text: '50');
  final _people = TextEditingController(text: '2');
  int _percent = 10;

  @override
  void dispose() {
    _bill.dispose();
    _people.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bill = TripConvertMath.parse(_bill.text);
    final people = int.tryParse(_people.text.trim()) ?? 1;
    final r = bill == null ? null : TripConvertMath.tip(bill, _percent, people);
    String money(double v) => '${TripConvertMath.show(v)} ${widget.currency}';
    return TripSectionBlock(
      title: l10n.convertTip,
      icon: Icons.room_service_outlined,
      initiallyOpen: false,
      children: [
        TextField(
          key: const Key('convert-tip-bill'),
          controller: _bill,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l10n.convertTipBill,
            suffixText: widget.currency,
          ),
        ),
        const SizedBox(height: 8),
        TripSectionChoices<int>(
          keyPrefix: 'convert-tip-percent',
          values: const [0, 5, 10, 15, 20],
          codeOf: (p) => '$p',
          labelOf: (p) => '$p%',
          selected: _percent,
          onChanged: (p) => setState(() => _percent = p ?? _percent),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('convert-tip-people'),
          controller: _people,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.convertTipPeople),
        ),
        const SizedBox(height: 8),
        if (r != null)
          Text(
            l10n.convertTipResult(money(r.tip), money(r.total), money(r.each)),
            key: const Key('convert-tip-result'),
            style: const TextStyle(color: AmaterasuColors.accentGold),
          ),
      ],
    );
  }
}
