class TripTravellerProfileData {
  const TripTravellerProfileData({
    this.hasEsimOrInternet,
    this.hasCheckedBaggage,
    this.hasCabinBaggage10Kg,
    this.hasAllergies,
    this.hasIntolerances,
    this.hasMedicalAccessibilityInfo,
    this.allergies = '',
    this.intolerances = '',
    this.medicalAccessibilityInfo = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
  });

  final bool? hasEsimOrInternet;
  final bool? hasCheckedBaggage;
  final bool? hasCabinBaggage10Kg;

  final bool? hasAllergies;
  final bool? hasIntolerances;
  final bool? hasMedicalAccessibilityInfo;

  final String allergies;
  final String intolerances;
  final String medicalAccessibilityInfo;
  final String emergencyContactName;
  final String emergencyContactPhone;

  bool get hasProfile =>
      hasEsimOrInternet != null &&
      hasCheckedBaggage != null &&
      hasCabinBaggage10Kg != null &&
      hasAllergies != null &&
      hasIntolerances != null &&
      hasMedicalAccessibilityInfo != null;

  factory TripTravellerProfileData.fromMap(dynamic raw) {
    if (raw is! Map) {
      return const TripTravellerProfileData();
    }

    final allergies = _string(raw['allergies']);
    final intolerances = _string(raw['intolerances']);
    final medicalAccessibilityInfo = _string(raw['medicalAccessibilityInfo']);

    return TripTravellerProfileData(
      hasEsimOrInternet: raw['hasEsimOrInternet'] as bool?,
      hasCheckedBaggage: raw['hasCheckedBaggage'] as bool?,
      hasCabinBaggage10Kg: raw['hasCabinBaggage10Kg'] as bool?,

      // Backward compatibility:
      // - se il nuovo bool esiste, è autoritativo;
      // - se manca ma esiste già un dettaglio, inferiamo SI;
      // - se manca ed il dettaglio è vuoto, resta null e l'utente
      //   dovrà dare esplicitamente una risposta.
      hasAllergies:
          raw['hasAllergies'] as bool? ?? (allergies.isNotEmpty ? true : null),
      hasIntolerances:
          raw['hasIntolerances'] as bool? ??
          (intolerances.isNotEmpty ? true : null),
      hasMedicalAccessibilityInfo:
          raw['hasMedicalAccessibilityInfo'] as bool? ??
          (medicalAccessibilityInfo.isNotEmpty ? true : null),

      allergies: allergies,
      intolerances: intolerances,
      medicalAccessibilityInfo: medicalAccessibilityInfo,
      emergencyContactName: _string(raw['emergencyContactName']),
      emergencyContactPhone: _string(raw['emergencyContactPhone']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hasEsimOrInternet': hasEsimOrInternet,
      'hasCheckedBaggage': hasCheckedBaggage,
      'hasCabinBaggage10Kg': hasCabinBaggage10Kg,
      'hasAllergies': hasAllergies,
      'hasIntolerances': hasIntolerances,
      'hasMedicalAccessibilityInfo': hasMedicalAccessibilityInfo,
      'allergies': allergies.trim(),
      'intolerances': intolerances.trim(),
      'medicalAccessibilityInfo': medicalAccessibilityInfo.trim(),
      'emergencyContactName': emergencyContactName.trim(),
      'emergencyContactPhone': emergencyContactPhone.trim(),
    };
  }

  static String _string(dynamic value) {
    return value is String ? value.trim() : '';
  }
}

class TripMember {
  const TripMember({
    required this.uid,
    required this.role,
    required this.travellerProfileCompleted,
    required this.travellerProfile,
    this.joinedAt,
    this.username,
    this.firstName,
    this.lastName,
    this.photoUrl,
  });

  final String uid;
  final String role;
  final DateTime? joinedAt;

  final bool travellerProfileCompleted;
  final TripTravellerProfileData travellerProfile;

  /// Safe projection from the global profile.
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;

  bool get isAdmin => role == 'admin';

  String? get displayName {
    final parts = <String>[
      if (_notEmpty(firstName)) firstName!.trim(),
      if (_notEmpty(lastName)) lastName!.trim(),
    ];

    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    if (_notEmpty(username)) {
      return username!.trim();
    }

    return null;
  }

  factory TripMember.fromMap(Map<String, dynamic> data) {
    final rawProfile = data['profile'];
    final profile = rawProfile is Map
        ? Map<String, dynamic>.from(rawProfile)
        : const <String, dynamic>{};

    final joinedAtMilliseconds = data['joinedAt'];

    return TripMember(
      uid: data['uid'] as String? ?? '',
      role: data['role'] as String? ?? 'traveler',
      joinedAt: joinedAtMilliseconds is num
          ? DateTime.fromMillisecondsSinceEpoch(joinedAtMilliseconds.toInt())
          : null,
      travellerProfileCompleted:
          data['travellerProfileCompleted'] as bool? ?? false,
      travellerProfile: TripTravellerProfileData.fromMap(
        data['travellerProfile'],
      ),
      username: _nullableString(profile['username']),
      firstName: _nullableString(profile['firstName']),
      lastName: _nullableString(profile['lastName']),
      photoUrl: _nullableString(profile['photoUrl']),
    );
  }

  static bool _notEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static String? _nullableString(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }
}
