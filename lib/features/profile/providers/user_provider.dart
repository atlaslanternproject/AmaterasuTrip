import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/user_repository.dart';
final userRepositoryProvider =
    Provider<UserRepository>((ref) {
  return UserRepository(
    FirebaseFirestore.instance,
  );
});
