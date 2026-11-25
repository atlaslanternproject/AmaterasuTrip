// Test automatici delle preferenze "Aspetto" (Extra E, passo E1): valori
// ammessi e predefiniti, mappa salvata, valuta mostrata che segue quella
// predefinita, avvio dalla copia nel dispositivo, lettura del profilo una
// volta sola e salvataggio nel dispositivo e nel profilo.
// Casi, ad esempio: "unknown values fall back", "update saves on device and profile".

import 'dart:convert';

import 'package:amaterasutrip/core/appearance/amaterasu_appearance.dart';
import 'package:amaterasutrip/core/appearance/amaterasu_appearance_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAppearanceStore implements AmaterasuAppearanceStore {
  FakeAppearanceStore([this.remote]);

  AmaterasuAppearance? remote;
  int loads = 0;
  final saved = <AmaterasuAppearance>[];

  @override
  Future<AmaterasuAppearance?> load() async {
    loads++;
    return remote;
  }

  @override
  Future<void> save(AmaterasuAppearance appearance) async =>
      saved.add(appearance);
}

ProviderContainer container(FakeAppearanceStore store) {
  final c = ProviderContainer(
    overrides: [amaterasuAppearanceStoreProvider.overrideWithValue(store)],
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  test('defaults, saved map and unknown values', () {
    const a = AmaterasuAppearance();
    expect(a.toMap(), isEmpty);
    final b = AmaterasuAppearance.fromMap({
      'textScale': 120,
      'units': 'mi',
      'dateFormat': 'ymd',
      'timeFormat': '12',
      'defaultCurrency': 'EUR',
    });
    expect(b.toMap(), {
      'textScale': 120,
      'units': 'mi',
      'dateFormat': 'ymd',
      'timeFormat': '12',
      'defaultCurrency': 'EUR',
    });
    expect(b.shownCurrency, 'EUR');
    expect(
      AmaterasuAppearance.fromMap({'textScale': 150, 'units': 'leghe'}),
      const AmaterasuAppearance(),
    );
    expect(b.copyWith(displayCurrency: 'JPY').shownCurrency, 'JPY');
  });

  test('starts from the device, then reads the profile once', () async {
    SharedPreferences.setMockInitialValues({
      AmaterasuAppearanceController.prefsKey: jsonEncode({'textScale': 110}),
    });
    final store = FakeAppearanceStore(
      const AmaterasuAppearance(textScale: 130),
    );
    final c = container(store);
    expect(c.read(amaterasuAppearanceProvider).textScale, 100);
    await settle();
    expect(c.read(amaterasuAppearanceProvider).textScale, 130);
    expect(store.loads, 1);
  });

  test('update saves on device and profile', () async {
    SharedPreferences.setMockInitialValues({});
    final store = FakeAppearanceStore();
    final c = container(store);
    c.read(amaterasuAppearanceProvider);
    await settle();
    final ok = await c
        .read(amaterasuAppearanceProvider.notifier)
        .update(const AmaterasuAppearance(units: 'mi'));
    expect(ok, isTrue);
    expect(store.saved.single.units, 'mi');
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(AmaterasuAppearanceController.prefsKey),
      jsonEncode({'units': 'mi'}),
    );
  });
}
