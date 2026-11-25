// Itinerario demo della bozza: implementazione in memoria di
// TripItineraryRepository (non si salva, si perde ricaricando) con i dati
// di esempio di trip_itinerary_demo_data.dart, a partire da oggi.

import 'dart:async';

import '../models/trip_itinerary_item.dart';
import 'trip_itinerary_demo_data.dart';
import 'trip_itinerary_repository.dart';

class DemoTripItineraryRepository implements TripItineraryRepository {
  DemoTripItineraryRepository({DateTime? today})
    : _start = _day(today ?? DateTime.now()) {
    _items = tripItineraryDemoItems(_start);
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  final DateTime _start;
  late List<TripItineraryItem> _items;
  final _changes = StreamController<List<TripItineraryItem>>.broadcast();

  @override
  bool get isDemo => true;

  @override
  TripItineraryInfo info(String tripId) => TripItineraryInfo(
    start: _start,
    end: _start.add(const Duration(days: 3)),
    names: tripItineraryDemoNames,
    catalog: tripItineraryDemoCatalog(_start),
  );

  @override
  Stream<List<TripItineraryItem>> watch(String tripId) async* {
    yield List.of(_items);
    yield* _changes.stream;
  }

  void _emit() => _changes.add(List.of(_items));

  @override
  Future<void> save(String tripId, TripItineraryItem item) async {
    final i = _items.indexWhere((e) => e.id == item.id);
    i < 0 ? _items.add(item) : _items[i] = item;
    _emit();
  }

  @override
  Future<void> delete(String tripId, String itemId) async {
    _items.removeWhere((e) => e.id == itemId);
    _emit();
  }

  @override
  Future<void> reorder(String tripId, List<String> itemIds) async {
    _items = [
      for (final item in _items)
        itemIds.contains(item.id)
            ? item.copyWith(order: itemIds.indexOf(item.id), time: () => null)
            : item,
    ];
    _emit();
  }
}
