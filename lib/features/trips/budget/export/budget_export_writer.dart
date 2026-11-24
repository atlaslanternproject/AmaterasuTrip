// Scrive l'esportazione delle spese in CSV pronto per Excel (separatore ";",
// virgola decimale in italiano, UTF-8 con BOM) e in una pagina HTML da
// stampare o salvare come PDF dal browser.

import 'package:amaterasutrip/features/trips/budget/presentation/budget_money_input.dart';
import 'budget_export_model.dart';

/// Visible texts of the export, in the chosen language.
class BudgetExportTexts {
  const BudgetExportTexts({
    required this.title,
    required this.expensesHeader,
    required this.refundsHeader,
    required this.totalsHeader,
    required this.personsHeader,
    required this.label,
    required this.decimalComma,
  });

  final String title;

  /// Column names of each table.
  final List<String> expensesHeader;
  final List<String> refundsHeader;
  final List<String> totalsHeader;
  final List<String> personsHeader;

  /// Readable text for a code (category, status, "personal", "cancelled").
  final String Function(String code) label;
  final bool decimalComma;
}

class BudgetExportWriter {
  const BudgetExportWriter(this.data, this.texts);

  final BudgetExport data;
  final BudgetExportTexts texts;

  String money(int minor, String currency) {
    String text;
    try {
      text = BudgetMoneyInput.plainText(minor, currency);
    } catch (_) {
      text = '$minor';
    }
    return texts.decimalComma ? text.replaceAll('.', ',') : text;
  }

  String _people(Map<String, int> values, String currency) => values.entries
      .map((e) => '${e.key} ${money(e.value, currency)}')
      .join(' · ');

  /// The tables: (title, header, rows).
  List<(String, List<String>, List<List<String>>)> get tables {
    final l = texts.label;
    final shares = data.sharesByPerson;
    final paid = data.paidByPerson;
    final people = {...shares.keys, ...paid.keys}.toList()
      ..sort((a, b) => '${a.$1}${a.$2}'.compareTo('${b.$1}${b.$2}'));
    return [
      (
        texts.title,
        texts.expensesHeader,
        [
          for (final e in data.expenses)
            [
              e.date,
              e.title,
              l(e.category),
              e.cancelled ? l('cancelled') : l(e.status),
              l(e.personal ? 'personal' : 'shared'),
              money(e.totalMinor, e.currency),
              e.currency,
              _people(e.paid, e.currency),
              _people(e.shares, e.currency),
              e.notes ?? '',
            ],
        ],
      ),
      (
        '',
        texts.refundsHeader,
        [
          for (final r in data.refunds)
            [
              r.expense,
              r.from,
              r.to,
              money(r.minor, r.currency),
              r.currency,
              l(r.status),
            ],
        ],
      ),
      (
        '',
        texts.totalsHeader,
        [
          for (final entry in data.totals.entries)
            [entry.key, money(entry.value, entry.key)],
        ],
      ),
      (
        '',
        texts.personsHeader,
        [
          for (final key in people)
            [
              key.$1,
              key.$2,
              money(shares[key] ?? 0, key.$2),
              money(paid[key] ?? 0, key.$2),
            ],
        ],
      ),
    ];
  }

  String csv() {
    String cell(String value) => '"${value.replaceAll('"', '""')}"';
    final lines = <String>[];
    for (final (title, header, rows) in tables) {
      if (title.isNotEmpty) lines.add(cell(title));
      lines.add(header.map(cell).join(';'));
      for (final row in rows) {
        lines.add(row.map(cell).join(';'));
      }
      lines.add('');
    }
    return '﻿${lines.join('\r\n')}';
  }

  String html() {
    String esc(String value) => value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
    final body = StringBuffer();
    for (final (_, header, rows) in tables) {
      body.write('<table><thead><tr>');
      for (final h in header) {
        body.write('<th>${esc(h)}</th>');
      }
      body.write('</tr></thead><tbody>');
      for (final row in rows) {
        body.write('<tr>${row.map((c) => '<td>${esc(c)}</td>').join()}</tr>');
      }
      body.write('</tbody></table>');
    }
    return '<!doctype html><html><head><meta charset="utf-8">'
        '<title>${esc(texts.title)}</title><style>'
        'body{font-family:sans-serif;font-size:11px;margin:16px}'
        'h1{font-size:16px}table{border-collapse:collapse;width:100%;'
        'margin-bottom:18px}th,td{border:1px solid #999;padding:4px;'
        'text-align:left;vertical-align:top}th{background:#eee}'
        '</style></head><body><h1>${esc(texts.title)}</h1>$body</body></html>';
  }
}
