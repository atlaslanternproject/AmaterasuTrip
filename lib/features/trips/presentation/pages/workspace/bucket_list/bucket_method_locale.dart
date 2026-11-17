// Parte di trip_bucket_list_page.dart: lingua corrente della pagina.

// ignore_for_file: invalid_use_of_protected_member
part of 'trip_bucket_list_page.dart';

extension _BucketMethodLocale on _TripBucketListPageState {
  bool get _it =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'it';
}
