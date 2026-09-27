import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class TripCoverUploadResult {
  const TripCoverUploadResult({
    required this.downloadUrl,
    required this.storagePath,
  });

  final String downloadUrl;
  final String storagePath;
}

class TripCoverStorageService {
  TripCoverStorageService({
    FirebaseAuth? firebaseAuth,
    FirebaseStorage? firebaseStorage,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseStorage _firebaseStorage;

  Future<TripCoverUploadResult> uploadTripCover({
    required String tripId,
    required XFile cover,
  }) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final normalizedTripId = tripId.trim();

    if (normalizedTripId.isEmpty) {
      throw ArgumentError.value(tripId, 'tripId', 'Trip ID cannot be empty.');
    }

    final extension = _extractExtension(cover.path);

    final storagePath =
        'users/${user.uid}/trips/$normalizedTripId/cover/'
        'cover_${DateTime.now().millisecondsSinceEpoch}.$extension';

    final reference = _firebaseStorage.ref().child(storagePath);

    await reference.putFile(File(cover.path));

    final downloadUrl = await reference.getDownloadURL();

    return TripCoverUploadResult(
      downloadUrl: downloadUrl,
      storagePath: storagePath,
    );
  }

  Future<void> deleteTripCover(String? storagePath) async {
    if (storagePath == null || storagePath.trim().isEmpty) {
      return;
    }

    await _firebaseStorage.ref().child(storagePath).delete();
  }

  String _extractExtension(String path) {
    final lastDot = path.lastIndexOf('.');

    if (lastDot == -1 || lastDot == path.length - 1) {
      return 'jpg';
    }

    return path.substring(lastDot + 1).toLowerCase();
  }
}
