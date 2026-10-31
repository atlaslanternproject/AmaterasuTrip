// ignore_for_file: invalid_use_of_protected_member
part of 'trip_bucket_list_page.dart';

extension _BucketMethodCategoryKey on _TripBucketListPageState {
  String _categoryKey(String input) {
    final ascii = input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[àáâäãå]'), 'a')
        .replaceAll(RegExp('[èéêë]'), 'e')
        .replaceAll(RegExp('[ìíîï]'), 'i')
        .replaceAll(RegExp('[òóôöõ]'), 'o')
        .replaceAll(RegExp('[ùúûü]'), 'u')
        .replaceAll(RegExp('[ç]'), 'c')
        .replaceAll(RegExp('[ñ]'), 'n');
    final slug = ascii
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.length > 80 ? slug.substring(0, 80) : slug;
  }
}
