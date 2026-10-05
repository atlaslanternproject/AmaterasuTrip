enum TripNotificationCategory {
  departureDates,
  itineraryReminders,
  itineraryUpdates,
  bookingReminders,
  bookingUpdates,
  bucketList,
  bucketListVotes,
  budget,
  newExpenses,
  expenseChanges,
  reimbursements,
  travellers,
  invitations,
  rolesPermissions,
  groupActivity,
  sharedNotes,
  media,
  memories,
  cloudArchive,
  sync,
  tripInformationChanges,
  tripStatus,
  importantCommunications,
}

extension TripNotificationCategoryStorage on TripNotificationCategory {
  String get storageKey {
    return switch (this) {
      TripNotificationCategory.departureDates => 'departure_dates',
      TripNotificationCategory.itineraryReminders => 'itinerary_reminders',
      TripNotificationCategory.itineraryUpdates => 'itinerary_updates',
      TripNotificationCategory.bookingReminders => 'booking_reminders',
      TripNotificationCategory.bookingUpdates => 'booking_updates',
      TripNotificationCategory.bucketList => 'bucket_list',
      TripNotificationCategory.bucketListVotes => 'bucket_list_votes',
      TripNotificationCategory.budget => 'budget',
      TripNotificationCategory.newExpenses => 'new_expenses',
      TripNotificationCategory.expenseChanges => 'expense_changes',
      TripNotificationCategory.reimbursements => 'reimbursements',
      TripNotificationCategory.travellers => 'travellers',
      TripNotificationCategory.invitations => 'invitations',
      TripNotificationCategory.rolesPermissions => 'roles_permissions',
      TripNotificationCategory.groupActivity => 'group_activity',
      TripNotificationCategory.sharedNotes => 'shared_notes',
      TripNotificationCategory.media => 'media',
      TripNotificationCategory.memories => 'memories',
      TripNotificationCategory.cloudArchive => 'cloud_archive',
      TripNotificationCategory.sync => 'sync',
      TripNotificationCategory.tripInformationChanges =>
        'trip_information_changes',
      TripNotificationCategory.tripStatus => 'trip_status',
      TripNotificationCategory.importantCommunications =>
        'important_communications',
    };
  }
}

class TripNotificationPreferences {
  const TripNotificationPreferences({
    this.masterEnabled = true,
    this.values = const <TripNotificationCategory, bool>{},
  });

  final bool masterEnabled;
  final Map<TripNotificationCategory, bool> values;

  bool isEnabled(TripNotificationCategory category) {
    return values[category] ?? true;
  }

  TripNotificationPreferences copyWith({
    bool? masterEnabled,
    Map<TripNotificationCategory, bool>? values,
  }) {
    return TripNotificationPreferences(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      values: values ?? this.values,
    );
  }

  TripNotificationPreferences withCategory(
    TripNotificationCategory category,
    bool value,
  ) {
    return copyWith(
      values: <TripNotificationCategory, bool>{...values, category: value},
    );
  }
}
