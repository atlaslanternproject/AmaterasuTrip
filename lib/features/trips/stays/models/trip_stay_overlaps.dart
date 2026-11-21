// Coppie di soggiorni attivi che si sovrappongono nelle date. Serve solo
// per un avviso: due alloggi nella stessa notte non sono vietati.

import 'trip_stay.dart';

abstract final class TripStayOverlaps {
  /// Every overlapping pair once, in list order.
  static List<(TripStay, TripStay)> pairs(List<TripStay> stays) {
    final result = <(TripStay, TripStay)>[];
    for (var i = 0; i < stays.length; i++) {
      for (var j = i + 1; j < stays.length; j++) {
        if (stays[i].overlaps(stays[j])) result.add((stays[i], stays[j]));
      }
    }
    return result;
  }
}
