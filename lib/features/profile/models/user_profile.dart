class UserProfile {
  const UserProfile({
    required this.uid,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.bio,
    this.photoUrl,
    this.photoPath,
  });

  final String uid;
  final String username;
  final String? email;

  final String? firstName;
  final String? lastName;
  final String? bio;

  final String? photoUrl;
  final String? photoPath;

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
      photoUrl: data['photoUrl'] as String?,
      photoPath: data['photoPath'] as String?,
    );
  }
}
