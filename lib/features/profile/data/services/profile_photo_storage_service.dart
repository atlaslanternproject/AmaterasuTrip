import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotoUploadResult {
  const ProfilePhotoUploadResult({
    required this.downloadUrl,
    required this.storagePath,
  });

  final String downloadUrl;
  final String storagePath;
}

class ProfilePhotoStorageService {
  ProfilePhotoStorageService({
    FirebaseAuth? firebaseAuth,
    FirebaseStorage? firebaseStorage,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseStorage _firebaseStorage;

  Future<ProfilePhotoUploadResult> uploadProfilePhoto(XFile photo) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final extension = _extractExtension(photo.path);

    final storagePath =
        'users/${user.uid}/profile/profile_${DateTime.now().millisecondsSinceEpoch}.$extension';

    final reference = _firebaseStorage.ref().child(storagePath);

    await reference.putFile(File(photo.path));

    final downloadUrl = await reference.getDownloadURL();

    return ProfilePhotoUploadResult(
      downloadUrl: downloadUrl,
      storagePath: storagePath,
    );
  }

  Future<void> deleteProfilePhoto(String? storagePath) async {
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
