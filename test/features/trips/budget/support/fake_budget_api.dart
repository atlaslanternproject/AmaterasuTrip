// Test doubles of Firestore results: implementing them is intended here.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:amaterasutrip/features/trips/budget/data/personal_trip_budget_repository.dart';
import 'package:amaterasutrip/features/trips/budget/models/personal_trip_budget.dart';
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

/// Like a Firestore listener: every subscriber gets the current value.
Stream<T> _replay<T>(T value) => Stream.multi((listener) {
  listener.add(value);
});

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

  final _personalBudget = FakePersonalBudgetRepository();

  @override
  PersonalTripBudgetRepository get personalBudgetRepository => _personalBudget;
  final fxPins = <String>[];
  Map<String, String> categories = const {};

  @override
  Stream<Map<String, String>> budgetCategories() => _replay(categories);

  /// Pending revision proposals and cancellation requests by expense.
  Map<String, List<FakeDoc>> proposalDocs = const {};
  Map<String, Map<String, dynamic>> cancellations = const {};

  /// Revision records by expense ID.
  Map<String, List<FakeDoc>> revisionDocs = const {};

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> proposals(String expenseId) =>
      _replay(FakeQuery(proposalDocs[expenseId] ?? const []));

  @override
  Stream<Map<String, dynamic>?> cancellationRequest(String expenseId) =>
      _replay(cancellations[expenseId]);

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> expenseRecords(
    String expenseId, {
    required bool private,
    required String collection,
  }) => _replay(
    FakeQuery(
      collection == 'revisions'
          ? (revisionDocs[expenseId] ?? const [])
          : const [],
    ),
  );

  @override
  Future<void> ensureExpenseFx({
    required String expenseId,
    required bool private,
  }) async {
    fxPins.add(expenseId);
  }

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
  ) => _replay(FakeQuery(refunds[expenseId] ?? const []));

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> sharedExpenses() =>
      _replay(FakeQuery(shared));

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> privateExpenses() =>
      _replay(FakeQuery(private));

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

/// Personal budget kept in memory instead of Firestore.
class FakePersonalBudgetRepository extends PersonalTripBudgetRepository {
  FakePersonalBudgetRepository([this.budget]);

  PersonalTripBudget? budget;

  @override
  Stream<PersonalTripBudget?> watch(String tripId) => _replay(budget);

  @override
  Future<void> save(String tripId, PersonalTripBudget value) async {
    budget = value;
  }

  @override
  Future<void> remove(String tripId) async {
    budget = null;
  }
}

/// Shared or private expense document in the stored format.
FakeDoc expenseDoc(
  String id, {
  required String category,
  required int total,
  String currency = 'EUR',
  String status = 'paid',
  Map<String, int> shares = const {},
  Map<String, int> advances = const {},
  String? day,
  Map<String, dynamic> extra = const {},
}) {
  Map<String, dynamic> money(int value) => {
    'currency': currency,
    'minorUnits': value,
  };
  return FakeDoc(id, {
    'title': id,
    'category': category,
    'snapshot': {
      'total': money(total),
      'status': status,
      'shares': {for (final e in shares.entries) e.key: money(e.value)},
      'advances': {for (final e in advances.entries) e.key: money(e.value)},
    },
    'participantUids': {...shares.keys, ...advances.keys}.toList(),
    'expenseDate': ?day,
    'version': 1,
    ...extra,
  });
}
