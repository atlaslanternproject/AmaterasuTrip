// Parte di trip_bucket_list_page.dart: scelta tra testo italiano
// e inglese (_t).

// ignore_for_file: invalid_use_of_protected_member
part of 'trip_bucket_list_page.dart';

extension _BucketMethodTranslation on _TripBucketListPageState {
  // TODO(audit): L5 testi italiano/inglese scritti nel codice (~137 nella bucket list): spostarli in lib/l10n.
  String _t(String it, String en) => _it ? it : en;
}
