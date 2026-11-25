// Sezione "Arrivo, accesso e tassa" dell'editor di un alloggio (aggiunte
// facoltative v2): arrivo tardivo (orario e contatto della reception),
// codice della porta, Wi-Fi, istruzioni di accesso e tassa di soggiorno a
// persona per notte. Contiene anche il suo stato modificabile.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amaterasutrip/features/trips/sections/editor/trip_section_cost_field.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_pickers.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_extras.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_draft.dart';
import 'trip_stay_editor_section.dart';

class TripStayExtrasDraft {
  TripStayExtrasDraft(TripStayExtras? initial, String currency)
    : lateArrivalTime = initial?.lateArrivalTime,
      reception = TextEditingController(text: initial?.receptionContact),
      doorCode = TextEditingController(text: initial?.doorCode),
      wifiName = TextEditingController(text: initial?.wifiName),
      wifiPassword = TextEditingController(text: initial?.wifiPassword),
      access = TextEditingController(text: initial?.accessNotes),
      persons = TextEditingController(
        text: initial?.taxPersons?.toString() ?? '',
      ),
      tax = TripSectionCostDraft(
        minorUnits: initial?.taxMinorUnits,
        currency: initial?.taxCurrency,
        fallback: currency,
      );

  String? lateArrivalTime;
  final TextEditingController reception;
  final TextEditingController doorCode;
  final TextEditingController wifiName;
  final TextEditingController wifiPassword;
  final TextEditingController access;
  final TextEditingController persons;
  final TripSectionCostDraft tax;

  TripStayExtras toExtras() => TripStayExtras(
    lateArrivalTime: lateArrivalTime,
    receptionContact: reception.text,
    doorCode: doorCode.text,
    wifiName: wifiName.text,
    wifiPassword: wifiPassword.text,
    accessNotes: access.text,
    taxMinorUnits: tax.minorUnits,
    taxCurrency: tax.savedCurrency,
    taxPersons: int.tryParse(persons.text.trim()),
  );

  void dispose() {
    for (final c in [reception, doorCode, wifiName, wifiPassword, access]) {
      c.dispose();
    }
    persons.dispose();
    tax.dispose();
  }
}

class TripStayArrivalSection extends StatelessWidget {
  const TripStayArrivalSection({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final TripStayDraft draft;
  final VoidCallback onChanged;

  Widget _text(String key, TextEditingController c, String label, int max) =>
      TextField(
        key: Key('stay-$key'),
        controller: c,
        maxLength: max,
        decoration: InputDecoration(labelText: label),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final e = draft.extras;
    return TripStayEditorSection(
      title: l10n.staysSectionArrival,
      icon: Icons.vpn_key_outlined,
      children: [
        TripSectionTimeButton(
          fieldKey: 'stay-late-arrival',
          label: l10n.staysLateArrival,
          value: e.lateArrivalTime,
          onChanged: (v) {
            e.lateArrivalTime = v;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _text(
          'reception',
          e.reception,
          l10n.staysReception,
          TripStayExtras.contactMax,
        ),
        _text('door-code', e.doorCode, l10n.staysDoorCode, 100),
        _text('wifi-name', e.wifiName, l10n.staysWifiName, 100),
        _text('wifi-password', e.wifiPassword, l10n.staysWifiPassword, 100),
        TextField(
          key: const Key('stay-access-notes'),
          controller: e.access,
          minLines: 2,
          maxLines: 5,
          maxLength: TripStayExtras.notesMax,
          decoration: InputDecoration(labelText: l10n.staysAccessNotes),
        ),
        TripSectionCostField(
          keyPrefix: 'stay-tax',
          draft: e.tax,
          label: l10n.staysCityTax,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('stay-tax-persons'),
          controller: e.persons,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 2,
          decoration: InputDecoration(
            labelText: l10n.staysCityTaxPersons,
            helperText: l10n.staysCityTaxPersonsHint,
          ),
        ),
      ],
    );
  }
}
