// Test doubles of Firestore results: implementing them is intended here.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Minimal Firestore document for widget tests (no Firebase needed).
class FakeDoc implements QueryDocumentSnapshot<Map<String, dynamic>> {
  FakeDoc(this.id, this._data);

  @override
  final String id;
  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic> data() => _data;

  @override
  bool get exists => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuery implements QuerySnapshot<Map<String, dynamic>> {
  FakeQuery(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  int get size => docs.length;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// BudgetApi with in-memory data; records the calls made by the screens.
class FakeBudgetApi extends BudgetApi {
  FakeBudgetApi({
    this.uid = 'A',
    this.members = const [],
    this.refunds = const {},
    this.shared = const [],
    this.private = const [],
    this.historyResponse = const {'events': []},
    this.currency = 'EUR',
  }) : super('trip1');

  final String uid;

  /// Current trip members: {'uid': ..., 'name': ...}.
  final List<Map<String, String>> members;
  final Map<String, List<FakeDoc>> refunds;
  final List<FakeDoc> shared;
  final List<FakeDoc> private;
  final Map<String, dynamic> historyResponse;
  final String currency;

  final closures = <Map<String, String>>[];

  @override
  String get currentUid => uid;

  @override
  Future<List<Map<String, String>>> travelers() async => members;

  @override
  Future<Map<String, String>> get travelerNameMap async => {
    for (final member in members) member['uid']!: member['name']!,
  };

  @override
  Future<String> tripCurrency() async => currency;

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> reimbursements(
    String expenseId,
  ) => Stream.value(FakeQuery(refunds[expenseId] ?? const []));

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> sharedExpenses() =>
      Stream.value(FakeQuery(shared));

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> privateExpenses() =>
      Stream.value(FakeQuery(private));

  @override
  Future<Map<String, dynamic>> history({
    String? expenseId,
    bool private = false,
  }) async => historyResponse;

  @override
  Future<void> get syncParticipantNames => Future.value();

  @override
  Future<void> closeFormerTravelerDebt({
    required String expenseId,
    required String debtorUid,
    required String reason,
  }) async {
    closures.add({
      'expenseId': expenseId,
      'debtorUid': debtorUid,
      'reason': reason,
    });
  }
}

Map<String, dynamic> eur(int minorUnits) => {
  'currency': 'EUR',
  'minorUnits': minorUnits,
};

/// Wraps [child] in a localized app, like the real one.
Widget budgetTestApp(Widget child, {String locale = 'it'}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
