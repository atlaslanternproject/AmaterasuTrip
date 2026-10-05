import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_notification_preferences.dart';

class TripNotificationPreferencesRepository {
  const TripNotificationPreferencesRepository();

  Future<TripNotificationPreferences> load({
    required String uid,
    required String tripId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final prefix = _prefix(uid: uid, tripId: tripId);

    final values = <TripNotificationCategory, bool>{};

    for (final category in TripNotificationCategory.values) {
      values[category] =
          preferences.getBool('$prefix.${category.storageKey}') ?? true;
    }

    return TripNotificationPreferences(
      masterEnabled: preferences.getBool('$prefix.master') ?? true,
      values: values,
    );
  }

  Future<void> setMaster({
    required String uid,
    required String tripId,
    required bool value,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(
      '${_prefix(uid: uid, tripId: tripId)}.master',
      value,
    );
  }

  Future<void> setCategory({
    required String uid,
    required String tripId,
    required TripNotificationCategory category,
    required bool value,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(
      '${_prefix(uid: uid, tripId: tripId)}.${category.storageKey}',
      value,
    );
  }

  String _prefix({required String uid, required String tripId}) {
    return 'trip_notifications.$uid.$tripId';
  }
}
