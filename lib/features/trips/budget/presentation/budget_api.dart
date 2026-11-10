import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'budget_currency.dart';
import '../models/budget_payment_plan.dart';

class BudgetApi {
  BudgetApi(this.tripId);

  final String tripId;

  // Created on first use, so the object can exist in widget tests.
  late final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  String get currentUid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Accesso richiesto.');
    }
    return uid;
  }

  late final Future<Map<String, String>> travelerNameMap = travelers().then((
    members,
  ) {
    final names = <String, String>{};

    for (final member in members) {
      final uid = member['uid'];
      final name = member['name'];

      if (uid != null && uid.isNotEmpty) {
        names[uid] = name != null && name.trim().isNotEmpty
            ? name.trim()
            : 'Viaggiatore';
      }
    }

    return names;
  });
  Future<String> tripCurrency() async {
    final doc = await _db.collection('trips').doc(tripId).get();
    if (!doc.exists) {
      throw StateError('Viaggio non trovato.');
    }
    final currency = doc.data()?['currency'];
    if (currency is! String || currency.isEmpty) {
      throw StateError('Valuta del viaggio non disponibile.');
    }
    return BudgetCurrency.normalize(currency);
  }

  Future<List<Map<String, String>>> travelers() async {
    final result = await _functions
        .httpsCallable('listTripMembers')
        .call<Map<String, dynamic>>({'tripId': tripId});

    final values = result.data['members'];
    if (values is! List) {
      throw StateError('Elenco viaggiatori non valido.');
    }

    return values
        .map((raw) {
          final data = Map<String, dynamic>.from(raw as Map);
          final uid = data['uid'] as String;
          final profile = data['profile'] is Map
              ? Map<String, dynamic>.from(data['profile'] as Map)
              : <String, dynamic>{};

          final first = profile['firstName']?.toString() ?? '';
          final last = profile['lastName']?.toString() ?? '';
          final username = profile['username']?.toString() ?? '';
          final display = '$first $last'.trim();

          return <String, String>{
            'uid': uid,
            'name': username.isNotEmpty
                ? username
                : (display.isNotEmpty ? display : 'Viaggiatore'),
            'photoUrl': profile['photoUrl']?.toString().trim() ?? '',
          };
        })
        .toList(growable: false);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> sharedExpenses() => _db
      .collection('trips')
      .doc(tripId)
      .collection('budgetSharedExpenses')
      .where('participantUids', arrayContains: currentUid)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> privateExpenses() => _db
      .collection('trips')
      .doc(tripId)
      .collection('budgetPrivateOwners')
      .doc(currentUid)
      .collection('expenses')
      .orderBy('createdAt', descending: true)
      .snapshots();

  /// Reimbursements and debt closures of one shared expense.
  Stream<QuerySnapshot<Map<String, dynamic>>> reimbursements(
    String expenseId,
  ) => _db
      .collection('trips')
      .doc(tripId)
      .collection('budgetSharedExpenses')
      .doc(expenseId)
      .collection('reimbursements')
      .snapshots();

  /// All custom categories are common to every member of this trip.
  Stream<Map<String, String>> budgetCategories() => _db
      .collection('trips')
      .doc(tripId)
      .collection('budgetCategories')
      .snapshots()
      .map(
        (snapshot) => <String, String>{
          for (final doc in snapshot.docs)
            'custom:${doc.id}': doc.data()['label']?.toString() ?? doc.id,
        },
      );

  Future<String> createBudgetCategory(String label) async {
    final response = await _functions
        .httpsCallable('createBudgetCategory')
        .call({'tripId': tripId, 'label': label});
    final value = Map<String, dynamic>.from(response.data as Map);
    final id = value['category'];
    if (id is! String || !id.startsWith('custom:')) {
      throw StateError('Category response invalid.');
    }
    return id;
  }

  Future<void> ensureExpenseFx({
    required String expenseId,
    required bool private,
  }) async {
    await _functions.httpsCallable('ensureBudgetExpenseFx').call({
      'tripId': tripId,
      'expenseId': expenseId,
      'visibility': private ? 'private' : 'shared',
    });
  }

  Future<void> overrideExpenseFx({
    required String expenseId,
    required bool private,
    required double rate,
    required String reason,
  }) async {
    await _functions.httpsCallable('overrideBudgetExpenseFx').call({
      'tripId': tripId,
      'expenseId': expenseId,
      'visibility': private ? 'private' : 'shared',
      'rate': rate,
      'reason': reason,
    });
  }

  /// B8.6: records traveler names inside shared expenses, so a traveler
  /// who leaves the trip keeps being shown by name. Best effort.
  late final Future<void> syncParticipantNames = _functions
      .httpsCallable('syncBudgetParticipantNames')
      .call({'tripId': tripId})
      .then((_) {}, onError: (Object _) {});

  /// B8.6: the creditor closes the remaining debt of a former traveler.
  Future<void> closeFormerTravelerDebt({
    required String expenseId,
    required String debtorUid,
    required String reason,
  }) async {
    await _functions.httpsCallable('closeBudgetDebt').call({
      'tripId': tripId,
      'expenseId': expenseId,
      'closureId': _db.collection('trips').doc().id,
      'debtorUid': debtorUid,
      'reason': reason.trim(),
    });
  }

  /// B8.6: history of one expense, or of the whole trip when [expenseId]
  /// is null. Only what the current traveler may see is returned.
  Future<Map<String, dynamic>> history({
    String? expenseId,
    bool private = false,
  }) async {
    final response = await _functions.httpsCallable('listBudgetHistory').call({
      'tripId': tripId,
      'expenseId': ?expenseId,
      if (expenseId != null) 'visibility': private ? 'private' : 'shared',
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> updateExpenseCategory({
    required String expenseId,
    required bool private,
    required String category,
  }) async {
    await _functions.httpsCallable('updateBudgetExpenseCategory').call({
      'tripId': tripId,
      'expenseId': expenseId,
      'visibility': private ? 'private' : 'shared',
      'category': category,
    });
  }

  Future<void> requestCancellation(String expenseId) async {
    await _functions.httpsCallable('requestBudgetCancellation').call({
      'tripId': tripId,
      'expenseId': expenseId,
    });
  }

  Future<void> decideCancellation(String expenseId, bool approved) async {
    await _functions.httpsCallable('decideBudgetCancellation').call({
      'tripId': tripId,
      'expenseId': expenseId,
      'approved': approved,
    });
  }

  Future<void> cancelPrivate(String expenseId) async {
    await _functions.httpsCallable('cancelPrivateBudgetExpense').call({
      'tripId': tripId,
      'expenseId': expenseId,
    });
  }

  Future<void> create({
    required String title,
    DateTime? expenseDate,
    required String category,
    required String notes,
    required bool shared,
    required String currency,
    required int minorUnits,
    required String status,
    required List<String> participants,
    Map<String, int>? customShares,
    BudgetPaymentPlan? paymentPlan,
  }) async {
    if (title.trim().isEmpty || title.trim().length > 100) {
      throw ArgumentError('Titolo obbligatorio (max 100 caratteri).');
    }

    if (notes.length > 2000) {
      throw ArgumentError('Note troppo lunghe.');
    }

    if (!const {
          'accommodation',
          'food',
          'transport',
          'activities',
          'shopping',
          'other',
        }.contains(category) &&
        !RegExp(r'^custom:[a-z0-9-]{1,60}$').hasMatch(category)) {
      throw ArgumentError('Categoria non valida.');
    }

    if (participants.isEmpty) {
      throw ArgumentError('Seleziona almeno un viaggiatore.');
    }

    if (minorUnits <= 0) {
      throw ArgumentError("L'importo deve essere positivo.");
    }

    final sorted = participants.toSet().toList()..sort();

    if (!shared && (sorted.length != 1 || sorted.single != currentUid)) {
      throw ArgumentError(
        'Una spesa personale puo riguardare solo il titolare.',
      );
    }

    if (sorted.length != participants.length) {
      throw ArgumentError('Viaggiatori duplicati.');
    }

    final shares = <String, dynamic>{};

    if (customShares != null) {
      if (!shared) {
        throw ArgumentError(
          'Le quote personalizzate richiedono una spesa condivisa.',
        );
      }

      if (customShares.length != sorted.length ||
          customShares.keys.toSet().difference(sorted.toSet()).isNotEmpty) {
        throw ArgumentError('Le quote non corrispondono ai partecipanti.');
      }

      var sum = 0;

      for (final uid in sorted) {
        final value = customShares[uid];

        if (value == null || value < 0) {
          throw ArgumentError('Quota non valida.');
        }

        sum += value;

        if (sum > minorUnits) {
          throw ArgumentError('La somma delle quote supera il totale.');
        }

        shares[uid] = {'currency': currency, 'minorUnits': value};
      }

      if (sum != minorUnits) {
        throw ArgumentError(
          'La somma delle quote deve coincidere con il totale.',
        );
      }
    } else {
      final base = minorUnits ~/ sorted.length;
      final remainder = minorUnits % sorted.length;

      for (var i = 0; i < sorted.length; i++) {
        shares[sorted[i]] = {
          'currency': currency,
          'minorUnits': base + (i < remainder ? 1 : 0),
        };
      }
    }

    final paid = status == 'paid';

    final declared = paymentPlan?.amountByPayer;

    if (paymentPlan != null) {
      paymentPlan.validate(
        status: status,
        expenseTotalMinor: minorUnits,
        advancesMinor: declared!,
        activeTravelerUids: {...sorted, currentUid},
      );

      if (declared.keys.any((uid) => uid != currentUid)) {
        throw ArgumentError(
          'I pagamenti di altri viaggiatori richiedono approvazione.',
        );
      }
    }

    final advances = paymentPlan == null
        ? (paid
              ? <String, dynamic>{
                  currentUid: {'currency': currency, 'minorUnits': minorUnits},
                }
              : <String, dynamic>{})
        : <String, dynamic>{
            for (final entry in declared!.entries)
              entry.key: {'currency': currency, 'minorUnits': entry.value},
          };

    final docId = _db.collection('trips').doc().id;
    await _functions.httpsCallable('createBudgetExpense').call({
      'tripId': tripId,
      'expenseId': docId,
      'visibility': shared ? 'shared' : 'private',
      'title': title.trim(),
      if (expenseDate != null)
        'expenseDate': expenseDate.toIso8601String().substring(0, 10),
      'category': category,
      'notes': notes.trim(),
      if (paymentPlan != null) 'paymentMethods': paymentPlan.toPayload(),
      'snapshot': {
        'total': {'currency': currency, 'minorUnits': minorUnits},
        'status': status,
        'shares': shares,
        'advances': advances,
      },
    });
    // A failed rate provider must never undo a successfully created expense.
    try {
      final tripBase = await tripCurrency();
      if (currency != tripBase) {
        unawaited(
          ensureExpenseFx(
            expenseId: docId,
            private: !shared,
          ).catchError((Object _) {}),
        );
      }
    } catch (_) {
      // The record remains valid in its original currency.
    }
  }
}
