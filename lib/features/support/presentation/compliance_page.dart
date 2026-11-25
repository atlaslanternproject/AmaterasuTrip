// Pagina "Conformità e normative" (Extra F): tabella con norma,
// riferimento ufficiale, "Ci riguarda?" e come la rispettiamo, letta dal
// file assets/compliance/compliance.json (it/en). Principi che applichiamo,
// non una certificazione né consulenza legale, con la data di verifica.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_chip.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class CompliancePage extends StatelessWidget {
  const CompliancePage({super.key});

  static const asset = 'assets/compliance/compliance.json';

  static Future<Map<String, dynamic>> _load() async =>
      jsonDecode(await rootBundle.loadString(asset, cache: false))
          as Map<String, dynamic>;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode == 'it'
        ? 'it'
        : 'en';
    String text(Object? map) =>
        map is Map ? (map[lang] ?? map['en'] ?? '').toString() : '';
    String applies(Object? v) => switch (v) {
      'yes' => l10n.supportComplianceYes,
      'no' => l10n.supportComplianceNo,
      _ => l10n.supportCompliancePartial,
    };
    Color color(Object? v) => switch (v) {
      'yes' => AmaterasuColors.success,
      'no' => AmaterasuColors.textMuted,
      _ => AmaterasuColors.accentGold,
    };
    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      appBar: AppBar(
        backgroundColor: AmaterasuColors.surfaceDeep,
        elevation: 0,
        title: Text(l10n.supportCompliance),
      ),
      body: FutureBuilder(
        future: _load(),
        builder: (context, snap) {
          final data = snap.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = (data['rows'] as List).cast<Map<String, dynamic>>();
          final checked = DateTime.tryParse('${data['checkedOn']}');
          return ListView(
            key: const Key('compliance-page'),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Text(
                l10n.supportComplianceDisclaimer(
                  checked == null
                      ? '—'
                      : MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(checked),
                ),
                style: const TextStyle(color: AmaterasuColors.textSecondary),
              ),
              const SizedBox(height: 12),
              for (final row in rows)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AmaterasuColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AmaterasuColors.borderWarm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text(row['norm']),
                        style: const TextStyle(
                          color: AmaterasuColors.textCream,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${l10n.supportComplianceApplies}: ${applies(row['applies'])}',
                        style: TextStyle(color: color(row['applies'])),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        text(row['how']),
                        style: const TextStyle(
                          color: AmaterasuColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      if ('${row['ref']}'.startsWith('http'))
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: AmaterasuLinkChip(link: '${row['ref']}'),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
