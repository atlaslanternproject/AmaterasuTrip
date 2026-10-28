import 'package:amaterasutrip/features/trips/models/trip_organizational_profile.dart';

class TripMember {
  const TripMember({
    required this.uid,
    required this.role,
    this.organizationalProfile,
    this.joinedAt,
    this.username,
    this.firstName,
    this.lastName,
    this.photoUrl,
  });

  final String uid;
  final String role;
  final DateTime? joinedAt;

  final TripOrganizationalProfile? organizationalProfile;

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
      organizationalProfile: data['organizationalProfile'] is Map
          ? TripOrganizationalProfile.fromMap(data['organizationalProfile'])
          : null,
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
