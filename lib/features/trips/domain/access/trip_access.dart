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
  manageStatus,
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
    // Solo OWNER puo' eliminare il viaggio.
    //
    // La matrice definitiva verrà modificata soltanto qui.
    switch (role) {
      case TripRole.owner:
        return true;
      case TripRole.traveler:
        return permission != TripPermission.deleteTrip;
    }
  }
}
