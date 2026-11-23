// Unisce i risultati di più richieste Firestore in un unico elenco in tempo
// reale: serve alle sezioni che i membri non possono leggere per intero
// (es. note private: le proprie più quelle condivise).

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Emits the joined list once every query has answered, then on each change.
Stream<List<T>> joinTripSectionQueries<T>(
  List<Query<Map<String, dynamic>>> parts,
  List<T> Function(QuerySnapshot<Map<String, dynamic>> snapshot) read,
) {
  final latest = List<List<T>?>.filled(parts.length, null);
  final subscriptions = <StreamSubscription<Object?>>[];
  late final StreamController<List<T>> controller;
  controller = StreamController<List<T>>(
    onListen: () {
      for (var i = 0; i < parts.length; i++) {
        subscriptions.add(
          parts[i].snapshots().listen((snapshot) {
            latest[i] = read(snapshot);
            if (latest.every((part) => part != null)) {
              controller.add([for (final part in latest) ...part!]);
            }
          }, onError: controller.addError),
        );
      }
    },
    onCancel: () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    },
  );
  return controller.stream;
}
