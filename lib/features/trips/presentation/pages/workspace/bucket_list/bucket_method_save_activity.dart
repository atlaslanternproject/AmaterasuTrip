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

    final normalizedName = name.trim().toLowerCase().replaceAll(
      RegExp(r'[^\p{L}\p{N}]', unicode: true),
      '',
    );
    final normalizedCity = city.trim().toLowerCase().replaceAll(
      RegExp(r'[^\p{L}\p{N}]', unicode: true),
      '',
    );
    final existingDocs = await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .collection('bucketList')
        .get();
    for (final doc in existingDocs.docs) {
      if (doc.id == existing?.id) continue;
      final fields = doc.data();
      final otherPlace = (fields['googlePlaceId'] as String? ?? '').trim();
      if (placeId != null &&
          placeId.trim().isNotEmpty &&
          otherPlace == placeId.trim()) {
        throw StateError(
          _t(
            'Questo luogo Google Maps è già nella Bucket List.',
            'This Google Maps place is already in the Bucket List.',
          ),
        );
      }
      String norm(Object? v) => (v?.toString() ?? '')
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
      if (normalizedName.isNotEmpty &&
          normalizedName == norm(fields['name']) &&
          normalizedCity == norm(fields['city'])) {
        throw StateError(
          _t(
            'Un’attività con lo stesso nome e città è già presente.',
            'An activity with the same name and city already exists.',
          ),
        );
      }
    }
    await _registerCategory(customCategory);
    final now = DateTime.now().toUtc();

    if (existing == null) {
      final id = (placeId?.trim().isNotEmpty ?? false)
          ? 'place_${base64Url.encode(utf8.encode(placeId!.trim())).replaceAll('=', '')}'
          : _activities.newActivityId(widget.tripId);

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
