class UserProfile {
  const UserProfile({
    required this.uid,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.bio,
  });

  final String uid;
  final String username;
  final String? email;

  final String? firstName;
  final String? lastName;
  final String? bio;

  factory UserProfile.fromFirestore({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return UserProfile(
      uid: uid,
      username: data['username'] as String? ?? '',
      email: data['email'] as String?,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      bio: data['bio'] as String?,
    );
  }
}
