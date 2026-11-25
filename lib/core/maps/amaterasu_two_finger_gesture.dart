// Gesto a due dita delle mappe Google dell'app (spostamento, zoom e
// rotazione con due dita; con un dito scorre la pagina). Spostato senza
// cambiamenti dalla mappa della destinazione per usarlo anche in Mappa e
// Itinerario.

import 'package:flutter/gestures.dart';

class AmaterasuTwoFingerMapGestureRecognizer extends OneSequenceGestureRecognizer {
  final Set<int> _pointers = <int>{};
  final Set<int> _trackedPointers = <int>{};

  bool _accepted = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);

    _pointers.add(event.pointer);
    _trackedPointers.add(event.pointer);

    if (_pointers.length >= 2 && !_accepted) {
      _accepted = true;
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointers.remove(event.pointer);

      if (_trackedPointers.remove(event.pointer)) {
        stopTrackingPointer(event.pointer);
      }
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (!_accepted) {
      resolve(GestureDisposition.rejected);
    }

    _pointers.clear();
    _trackedPointers.clear();
    _accepted = false;
  }

  @override
  String get debugDescription => 'twoFingerMapGesture';
}
