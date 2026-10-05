enum TripRole { owner, traveler }

enum TripPermission {
  viewSettings,

  viewInformation,
  editInformation,
  manageCover,

  viewTravellers,
  manageTravellers,
  manageInvitations,

  viewNotifications,
  manageNotifications,

  viewPrivacy,
  managePrivacy,
  manageRoles,

  viewManagement,
  manageArchive,
  exportTrip,
  duplicateTrip,
  deleteTrip,
}

class TripAccess {
  const TripAccess({required this.role});

  final TripRole role;

  bool get isOwner => role == TripRole.owner;

  bool get isTraveler => role == TripRole.traveler;

  bool can(TripPermission permission) {
    return TripAccessPolicy.can(role: role, permission: permission);
  }
}

abstract final class TripAccessPolicy {
  static TripRole? roleFor({
    required String ownerUid,
    required List<String> memberUids,
    required String userUid,
  }) {
    if (ownerUid == userUid) {
      return TripRole.owner;
    }

    if (memberUids.contains(userUid)) {
      return TripRole.traveler;
    }

    return null;
  }

  static bool can({
    required TripRole role,
    required TripPermission permission,
  }) {
    // Phase iniziale:
    // OWNER e TRAVELER possono fare tutto.
    //
    // La matrice definitiva verrà modificata soltanto qui.
    switch (role) {
      case TripRole.owner:
      case TripRole.traveler:
        return true;
    }
  }
}
