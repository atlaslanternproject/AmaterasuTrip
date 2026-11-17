import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// B8.7: every budget text has an Italian and an English version.
void main() {
  Map<String, dynamic> arb(String name) =>
      jsonDecode(File('lib/l10n/$name').readAsStringSync())
          as Map<String, dynamic>;

  final en = arb('app_en.arb');
  final it = arb('app_it.arb');
  final budgetKeys = en.keys.where(
    (key) => RegExp(r'^(bt[A-Z]|b8[5-7])').hasMatch(key),
  );

  test('budget texts exist in both languages and are not empty', () {
    expect(budgetKeys, isNotEmpty);
    for (final key in budgetKeys) {
      expect(it[key], isA<String>(), reason: 'missing Italian: $key');
      expect((it[key] as String).trim(), isNotEmpty, reason: key);
      expect((en[key] as String).trim(), isNotEmpty, reason: key);
    }
  });

  test('placeholders are the same in both languages', () {
    final placeholder = RegExp(r'\{(\w+)\}');
    for (final key in budgetKeys) {
      Set<String> names(String text) =>
          placeholder.allMatches(text).map((m) => m.group(1)!).toSet();
      expect(
        names(it[key] as String),
        names(en[key] as String),
        reason: key,
      );
    }
  });
}
