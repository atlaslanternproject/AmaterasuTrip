import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);

class NotificationSettings {
  const NotificationSettings({
    this.pushNotifications = true,
    this.tripReminders = true,
    this.itineraryReminders = true,
    this.tripUpdates = true,
    this.groupInvitations = true,
    this.groupActivity = true,
    this.appUpdates = true,
    this.importantCommunications = true,
    this.promotionalEmails = false,
  });

  final bool pushNotifications;
  final bool tripReminders;
  final bool itineraryReminders;
  final bool tripUpdates;
  final bool groupInvitations;
  final bool groupActivity;
  final bool appUpdates;
  final bool importantCommunications;
  final bool promotionalEmails;

  NotificationSettings copyWith({
    bool? pushNotifications,
    bool? tripReminders,
    bool? itineraryReminders,
    bool? tripUpdates,
    bool? groupInvitations,
    bool? groupActivity,
    bool? appUpdates,
    bool? importantCommunications,
    bool? promotionalEmails,
  }) {
    return NotificationSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      tripReminders: tripReminders ?? this.tripReminders,
      itineraryReminders: itineraryReminders ?? this.itineraryReminders,
      tripUpdates: tripUpdates ?? this.tripUpdates,
      groupInvitations: groupInvitations ?? this.groupInvitations,
      groupActivity: groupActivity ?? this.groupActivity,
      appUpdates: appUpdates ?? this.appUpdates,
      importantCommunications:
          importantCommunications ?? this.importantCommunications,
      promotionalEmails: promotionalEmails ?? this.promotionalEmails,
    );
  }
}

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  static const String _pushNotificationsKey = 'notifications_push';
  static const String _tripRemindersKey = 'notifications_trip_reminders';
  static const String _itineraryRemindersKey =
      'notifications_itinerary_reminders';
  static const String _tripUpdatesKey = 'notifications_trip_updates';
  static const String _groupInvitationsKey = 'notifications_group_invitations';
  static const String _groupActivityKey = 'notifications_group_activity';
  static const String _appUpdatesKey = 'notifications_app_updates';
  static const String _importantCommunicationsKey =
      'notifications_important_communications';
  static const String _promotionalEmailsKey =
      'notifications_promotional_emails';

  @override
  NotificationSettings build() {
    _loadSettings();
    return const NotificationSettings();
  }

  Future<void> _loadSettings() async {
    final preferences = await SharedPreferences.getInstance();

    state = NotificationSettings(
      pushNotifications:
          preferences.getBool(_pushNotificationsKey) ?? true,
      tripReminders: preferences.getBool(_tripRemindersKey) ?? true,
      itineraryReminders:
          preferences.getBool(_itineraryRemindersKey) ?? true,
      tripUpdates: preferences.getBool(_tripUpdatesKey) ?? true,
      groupInvitations:
          preferences.getBool(_groupInvitationsKey) ?? true,
      groupActivity: preferences.getBool(_groupActivityKey) ?? true,
      appUpdates: preferences.getBool(_appUpdatesKey) ?? true,
      importantCommunications:
          preferences.getBool(_importantCommunicationsKey) ?? true,
      promotionalEmails:
          preferences.getBool(_promotionalEmailsKey) ?? false,
    );
  }

  Future<void> setPushNotifications(bool value) async {
    state = state.copyWith(pushNotifications: value);
    await _saveBool(_pushNotificationsKey, value);
  }

  Future<void> setTripReminders(bool value) async {
    state = state.copyWith(tripReminders: value);
    await _saveBool(_tripRemindersKey, value);
  }

  Future<void> setItineraryReminders(bool value) async {
    state = state.copyWith(itineraryReminders: value);
    await _saveBool(_itineraryRemindersKey, value);
  }

  Future<void> setTripUpdates(bool value) async {
    state = state.copyWith(tripUpdates: value);
    await _saveBool(_tripUpdatesKey, value);
  }

  Future<void> setGroupInvitations(bool value) async {
    state = state.copyWith(groupInvitations: value);
    await _saveBool(_groupInvitationsKey, value);
  }

  Future<void> setGroupActivity(bool value) async {
    state = state.copyWith(groupActivity: value);
    await _saveBool(_groupActivityKey, value);
  }

  Future<void> setAppUpdates(bool value) async {
    state = state.copyWith(appUpdates: value);
    await _saveBool(_appUpdatesKey, value);
  }

  Future<void> setImportantCommunications(bool value) async {
    state = state.copyWith(importantCommunications: value);
    await _saveBool(_importantCommunicationsKey, value);
  }

  Future<void> setPromotionalEmails(bool value) async {
    state = state.copyWith(promotionalEmails: value);
    await _saveBool(_promotionalEmailsKey, value);
  }

  Future<void> _saveBool(String key, bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }
}