import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/data/budget_fx_service.dart';

void main() {
  test('reads a verified published quote, date and pair', () async {
    final service = BudgetFxService(
      load: (_) async =>
          '{"date":"2026-11-03","base":"EUR","quote":"JPY","rate":181.7}',
    );
    final fx = await service.latest('EUR', 'JPY');
    expect(fx.rate, 181.7);
    expect(fx.observedIso, '2026-11-03');
    expect(BudgetFxService.convertMinor(612000, 'EUR', 'JPY', fx), 1112004);
  });

  test('historical uses v2 date query, not a fake path', () async {
    Uri? used;
    final service = BudgetFxService(
      load: (url) async {
        used = url;
        return '{"date":"2026-10-30","base":"EUR","quote":"JPY","rate":180.0}';
      },
    );
    await service.historical('EUR', 'JPY', DateTime(2026, 11, 1));
    expect(used!.path, '/v2/rate/EUR/JPY');
    expect(used!.queryParameters['date'], '2026-11-01');
  });

  test('historical quote must not use the following day', () async {
    final service = BudgetFxService(load: (_) async =>
        '{"date":"2024-02-29","base":"EUR","quote":"JPY","rate":160}');
    await expectLater(service.historical('EUR', 'JPY', DateTime(2024, 2, 28)), throwsFormatException);
  });

  test('invalid quote is rejected instead of inventing a rate', () async {
    final service = BudgetFxService(
      load: (_) async =>
          '{"date":"2026-11-03","base":"EUR","quote":"JPY","rate":-1}',
    );
    await expectLater(service.latest('EUR', 'JPY'), throwsFormatException);
  });

  test('no conversion if provider rate is missing', () {
    expect(BudgetFxService.convertMinor(15000, 'EUR', 'JPY', null), isNull);
    expect(BudgetFxService.convertMinor(150, 'JPY', 'JPY', null), 150);
  });
}
