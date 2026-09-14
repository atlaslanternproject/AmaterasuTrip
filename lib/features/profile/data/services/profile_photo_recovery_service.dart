import 'package:shared_preferences/shared_preferences.dart';

class ProfilePhotoRecoveryService {
  static const String _pendingKey = 'profile_photo_pending';
  static const String _recoveredPathKey = 'profile_photo_recovered_path';

  Future<void> markPending() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_pendingKey, true);
    await preferences.remove(_recoveredPathKey);
  }

  Future<bool> isPending() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getBool(_pendingKey) ?? false;
  }

  Future<void> saveRecoveredPath(String path) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_recoveredPathKey, path);
  }

  Future<String?> consumeRecoveredPath() async {
    final preferences = await SharedPreferences.getInstance();

    final path = preferences.getString(_recoveredPathKey);

    if (path != null) {
      await preferences.remove(_recoveredPathKey);
    }

    return path;
  }

  Future<void> clearPending() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_pendingKey);
  }

  Future<void> clearRecovery() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_pendingKey);
    await preferences.remove(_recoveredPathKey);
  }
}
