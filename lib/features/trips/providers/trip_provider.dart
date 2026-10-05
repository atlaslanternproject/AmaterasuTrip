import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/trip_invite_repository.dart';
import '../data/repositories/trip_repository.dart';
import '../data/services/trip_cover_picker_service.dart';
import '../data/services/trip_cover_recovery_service.dart';
import '../data/services/trip_cover_storage_service.dart';
import '../domain/access/trip_access.dart';
import '../models/trip.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(FirebaseFirestore.instance);
});

final tripInviteRepositoryProvider = Provider<TripInviteRepository>((ref) {
  return TripInviteRepository();
});

final tripCoverPickerServiceProvider = Provider<TripCoverPickerService>((ref) {
  return TripCoverPickerService();
});

final tripCoverRecoveryServiceProvider = Provider<TripCoverRecoveryService>((
  ref,
) {
  return TripCoverRecoveryService();
});

final tripCoverStorageServiceProvider = Provider<TripCoverStorageService>((
  ref,
) {
  return TripCoverStorageService();
});

final _tripAuthStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userTripsProvider = StreamProvider.autoDispose<List<Trip>>((ref) {
  final user = ref.watch(_tripAuthStateProvider).asData?.value;

  if (user == null) {
    return Stream.value(const <Trip>[]);
  }

  return ref.watch(tripRepositoryProvider).watchUserTrips(uid: user.uid);
});

final tripProvider = StreamProvider.family<Trip?, String>((ref, tripId) {
  return ref.watch(tripRepositoryProvider).watchTrip(tripId);
});
final tripAccessProvider = Provider.family<TripAccess?, String>((ref, tripId) {
  final user = ref.watch(_tripAuthStateProvider).asData?.value;
  final trip = ref.watch(tripProvider(tripId)).asData?.value;

  if (user == null || trip == null) {
    return null;
  }

  final role = TripAccessPolicy.roleFor(
    ownerUid: trip.ownerUid,
    memberUids: trip.memberUids,
    userUid: user.uid,
  );

  if (role == null) {
    return null;
  }

  return TripAccess(role: role);
});
