import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/user_repository.dart';
import '../models/user_profile.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final repository = ref.watch(userRepositoryProvider);

  return repository.watchCurrentUserProfile();
});
