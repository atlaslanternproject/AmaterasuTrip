import 'bucket_firestore_paths.dart';

abstract final class BucketDeletionPaths {
  static String requests(String tripId, String activityId) {
    return '${BucketFirestorePaths.activity(tripId, activityId)}/deletionRequests';
  }

  static String request(String tripId, String activityId, String requestId) {
    if (requestId.isEmpty ||
        requestId.trim() != requestId ||
        requestId.contains('/')) {
      throw ArgumentError.value(requestId, 'requestId');
    }

    return '${requests(tripId, activityId)}/$requestId';
  }
}
