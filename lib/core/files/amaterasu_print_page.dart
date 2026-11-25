// Pagina da stampare o salvare come PDF, uguale in tutta l'app (COERENZA
// G4): un solo stile, testi protetti (& < > "), tabelle e titolo. Usata da
// spese, checklist e PDF del viaggio, poi aperta con amaterasuPrintHtml.

const _style =
    'body{font-family:sans-serif;font-size:11px;margin:16px}'
    'h1{font-size:18px;margin-bottom:2px}'
    'h2{font-size:14px;margin:14px 0 4px}'
    'table{border-collapse:collapse;width:100%;margin-bottom:14px}'
    'th,td{border:1px solid #999;padding:4px;text-align:left;'
    'vertical-align:top}th{background:#eee}'
    'ul{list-style:none;padding:0}li{padding:2px 0;font-size:13px}'
    '.muted{color:#555}';

/// Text safe inside HTML and attributes.
String amaterasuPrintEscape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// A table with a header row; every cell is escaped.
String amaterasuPrintTable(List<String> header, List<List<String>> rows) {
  final out = StringBuffer('<table><thead><tr>');
  for (final h in header) {
    out.write('<th>${amaterasuPrintEscape(h)}</th>');
  }
  out.write('</tr></thead><tbody>');
  for (final row in rows) {
    out.write(
      '<tr>${row.map((c) => '<td>${amaterasuPrintEscape(c)}</td>').join()}</tr>',
    );
  }
  out.write('</tbody></table>');
  return out.toString();
}

/// The whole page: [title] as page title and heading, an optional muted
/// [subtitle] (plain text, escaped) and the [body] (already HTML).
String amaterasuPrintPage({
  required String title,
  required String body,
  String? subtitle,
}) {
  final t = amaterasuPrintEscape(title);
  final sub = subtitle == null
      ? ''
      : '<div class="muted">${amaterasuPrintEscape(subtitle).replaceAll('\n', '<br>')}</div>';
  return '<!doctype html><html><head><meta charset="utf-8">'
      '<title>$t</title><style>$_style</style></head><body>'
      '<h1>$t</h1>$sub$body</body></html>';
}
