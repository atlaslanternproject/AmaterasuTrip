import 'package:shared_preferences/shared_preferences.dart';

class RecoveredTripCover {
  const RecoveredTripCover({required this.tripId, required this.path});

  final String tripId;
  final String path;
}

class TripCoverRecoveryService {
  static const String _pendingKey = 'trip_cover_pending';
  static const String _pendingTripIdKey = 'trip_cover_pending_trip_id';
  static const String _recoveredPathKey = 'trip_cover_recovered_path';

  Future<void> markPending(String tripId) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_pendingKey, true);
    await preferences.setString(_pendingTripIdKey, tripId);
    await preferences.remove(_recoveredPathKey);
  }

  Future<bool> isPending() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getBool(_pendingKey) ?? false;
  }

  Future<String?> getPendingTripId() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_pendingTripIdKey);
  }

  Future<void> saveRecoveredPath(String path) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_recoveredPathKey, path);
  }

  Future<RecoveredTripCover?> consumeRecoveredCover() async {
    final preferences = await SharedPreferences.getInstance();

    final tripId = preferences.getString(_pendingTripIdKey);
    final path = preferences.getString(_recoveredPathKey);

    if (tripId == null ||
        tripId.trim().isEmpty ||
        path == null ||
        path.trim().isEmpty) {
      return null;
    }

    await clearRecovery();

    return RecoveredTripCover(tripId: tripId, path: path);
  }

  Future<void> clearPending() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_pendingKey);
    await preferences.remove(_pendingTripIdKey);
  }

  Future<void> clearRecovery() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_pendingKey);
    await preferences.remove(_pendingTripIdKey);
    await preferences.remove(_recoveredPathKey);
  }
}
