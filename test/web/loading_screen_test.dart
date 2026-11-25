// Test automatico del caricamento con il sole (Extra G): la schermata è in
// index.html, sparisce solo quando l'app chiama amaterasuAppReady (prima
// pagina vera) o dopo un'uscita di sicurezza, e rispetta chi riduce le
// animazioni. Casi, ad esempio: "the sun waits for the app".

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the sun waits for the app', () {
    final index = File('web/index.html').readAsStringSync();
    expect(index, contains('id="amaterasu-loading"'));
    expect(index, contains('window.amaterasuAppReady = hide;'));
    expect(index, isNot(contains("addEventListener('flutter-first-frame'")));
    expect(index, contains('prefers-reduced-motion'));
    final dart = File(
      'lib/core/web/amaterasu_app_ready_web.dart',
    ).readAsStringSync();
    expect(dart, contains("@JS('amaterasuAppReady')"));
  });
}
