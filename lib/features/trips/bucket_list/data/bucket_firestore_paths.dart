abstract final class BucketFirestorePaths {
  static String activities(String tripId) {
    _check(tripId);
    return 'trips/$tripId/bucketList';
  }

  static String activity(String tripId, String activityId) {
    _check(activityId);
    return '${activities(tripId)}/$activityId';
  }

  static String votes(String tripId, String activityId) {
    return '${activity(tripId, activityId)}/votes';
  }

  static String vote(String tripId, String activityId, String userUid) {
    _check(userUid);
    return '${votes(tripId, activityId)}/$userUid';
  }

  static void _check(String value) {
    if (value.trim().isEmpty || value != value.trim() || value.contains('/')) {
      throw ArgumentError.value(value, 'id', 'Invalid document ID');
    }
  }
}
