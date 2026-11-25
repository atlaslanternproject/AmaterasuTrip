// Test automatico dei criteri per installare il sito come app (Extra B):
// manifest con nome, start_url, display standalone e icone 192/512 anche
// "maskable" (che esistono davvero), service worker minimo registrato.
// Casi, ad esempio: "manifest meets the install criteria".

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manifest meets the install criteria', () {
    final m =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(m['name'], isNotEmpty);
    expect(m['short_name'], isNotEmpty);
    expect(m['start_url'], '/');
    expect(m['display'], 'standalone');
    final icons = (m['icons'] as List).cast<Map<String, dynamic>>();
    for (final size in ['192x192', '512x512']) {
      expect(icons.where((i) => i['sizes'] == size), hasLength(2));
      expect(
        icons.where((i) => i['sizes'] == size && i['purpose'] == 'maskable'),
        hasLength(1),
      );
    }
    for (final icon in icons) {
      expect(File('web/${icon['src']}').existsSync(), isTrue);
    }
  });

  test('a minimal service worker is registered, without offline cache', () {
    final index = File('web/index.html').readAsStringSync();
    expect(index, contains("register('amaterasu_sw.js')"));
    expect(index, contains('apple-mobile-web-app-capable'));
    final worker = File('web/amaterasu_sw.js').readAsStringSync();
    expect(worker, contains("addEventListener('fetch'"));
    expect(worker, isNot(contains('caches.open')));
  });
}
