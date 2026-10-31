// ignore_for_file: invalid_use_of_protected_member
part of 'trip_bucket_list_page.dart';

extension _BucketMethodSaveActivity on _TripBucketListPageState {
  Future<void> _saveActivity({
    BucketListItem? existing,
    required String name,
    required String city,
    required String country,
    required BucketItemType type,
    required int? duration,
    required String notes,
    required String customCategory,
    required List<String> usefulLinks,
    required String? placeId,
    required String? address,
    required double? latitude,
    required double? longitude,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      throw StateError('Authentication required');
    }

    await _registerCategory(customCategory);
    final now = DateTime.now().toUtc();

    if (existing == null) {
      final id = _activities.newActivityId(widget.tripId);

      final item = BucketListItem(
        id: id,
        tripId: widget.tripId,
        name: name.trim(),
        city: city.trim(),
        country: country.trim(),
        type: type,
        durationMinutes: duration,
        notes: notes.trim(),
        customCategory: customCategory.trim().isEmpty
            ? null
            : customCategory.trim(),
        usefulLinks: usefulLinks,
        googlePlaceId: placeId,
        address: address,
        latitude: latitude,
        longitude: longitude,
        createdByUid: uid,
        createdAt: now,
        updatedAt: now,
      );

      await _activities.create(item);
    } else {
      final updated = BucketListItem(
        id: existing.id,
        tripId: existing.tripId,
        name: name.trim(),
        city: city.trim(),
        country: country.trim(),
        type: type,
        durationMinutes: duration,
        notes: notes.trim(),
        customCategory: customCategory.trim().isEmpty
            ? null
            : customCategory.trim(),
        usefulLinks: usefulLinks,
        googlePlaceId: placeId,
        address: address,
        latitude: latitude,
        longitude: longitude,
        createdByUid: existing.createdByUid,
        createdAt: existing.createdAt,
        updatedAt: now.isAfter(existing.updatedAt)
            ? now
            : existing.updatedAt.add(const Duration(milliseconds: 1)),
      );

      await _activities.update(updated);
    }
  }
}
