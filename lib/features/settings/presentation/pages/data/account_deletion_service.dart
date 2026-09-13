import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:amaterasutrip/core/storage/remember_me_storage.dart';

class AccountDeletionService {
  const AccountDeletionService._();

  static Future<void> deleteAccount() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    final user = auth.currentUser;

    debugPrint('');
    debugPrint('==========================================');
    debugPrint('[ACCOUNT DELETE] REAL DELETION START');
    debugPrint('==========================================');

    if (user == null) {
      debugPrint('[ACCOUNT DELETE] ERROR: no authenticated user');
      debugPrint('[ACCOUNT DELETE] PROCESS STOPPED');
      debugPrint('==========================================');
      debugPrint('');

      throw StateError('No authenticated user available for account deletion.');
    }

    final uid = user.uid;

    final providerIds = user.providerData
        .map((provider) => provider.providerId)
        .toList();

    debugPrint('[ACCOUNT DELETE] UID: $uid');
    debugPrint('[ACCOUNT DELETE] Email: ${user.email ?? 'null'}');
    debugPrint('[ACCOUNT DELETE] Providers: ${providerIds.join(', ')}');

    debugPrint('');
    debugPrint('[1] REAUTHENTICATION');

    if (providerIds.contains('password')) {
      debugPrint('[1] Password provider detected.');
    } else if (providerIds.contains('google.com')) {
      debugPrint('[1] Google provider detected.');
    } else {
      debugPrint('[1] Other provider detected.');
    }

    debugPrint(
      '[1] Reauthentication is handled before this service is called.',
    );
    debugPrint('[1] Continuing with authenticated user: $uid');

    debugPrint('');
    debugPrint('[2] GROUPS / TRIPS REFERENCES');
    debugPrint(
      '[2] No implemented groups/trips Firestore structure '
      'is currently available.',
    );
    debugPrint('[2] No groups/trips collection will be guessed or modified.');
    debugPrint('[2] This step must be extended when those structures exist.');

    debugPrint('');
    debugPrint('[3] USER-OWNED DATA');
    debugPrint(
      '[3] No additional confirmed user-owned Firestore '
      'collections currently exist in this deletion flow.',
    );
    debugPrint('[3] Only confirmed account documents will be processed.');

    debugPrint('');
    debugPrint('[4] USER PROFILE + USERNAME INDEX');

    final profileRef = firestore.collection('viaggiatori').doc(uid);

    DocumentReference<Map<String, dynamic>>? usernameRef;

    try {
      debugPrint('[4] Reading profile: viaggiatori/$uid');

      final profileSnapshot = await profileRef.get();

      if (!profileSnapshot.exists) {
        debugPrint('[4] ERROR: profile not found: viaggiatori/$uid');
        debugPrint('[4] Username index cannot be safely resolved.');
        debugPrint('[4] PROCESS STOPPED before any deletion.');

        throw StateError(
          'User profile not found. Safe account deletion cannot continue.',
        );
      }

      debugPrint('[4] Profile found: viaggiatori/$uid');

      final profileData = profileSnapshot.data();

      final usernameLower = profileData?['usernameLower'] as String?;

      if (usernameLower == null || usernameLower.trim().isEmpty) {
        debugPrint('[4] ERROR: usernameLower missing from user profile.');
        debugPrint('[4] Username index cannot be safely verified.');
        debugPrint('[4] PROCESS STOPPED before any deletion.');

        throw StateError('usernameLower missing from user profile.');
      }

      debugPrint('[4] usernameLower: $usernameLower');

      usernameRef = firestore.collection('usernames').doc(usernameLower);

      debugPrint('[4] Reading username index: usernames/$usernameLower');

      final usernameSnapshot = await usernameRef.get();

      if (!usernameSnapshot.exists) {
        debugPrint('[4] Username index not found: usernames/$usernameLower');
        debugPrint('[4] No username index deletion will be required.');
      } else {
        debugPrint('[4] Username index found: usernames/$usernameLower');

        final usernameData = usernameSnapshot.data();

        final indexedUid = usernameData?['uid'] as String?;

        debugPrint('[4] Username index UID: ${indexedUid ?? 'null'}');

        if (indexedUid != uid) {
          debugPrint(
            '[4] ERROR: username index UID does not match current user.',
          );
          debugPrint('[4] Current UID: $uid');
          debugPrint('[4] Indexed UID: ${indexedUid ?? 'null'}');
          debugPrint('[4] PROCESS STOPPED before any deletion.');

          throw StateError('Username index UID does not match current user.');
        }

        debugPrint('[4] Username index UID matches current user.');
      }

      debugPrint('');
      debugPrint('[4] All Firestore safety checks passed.');
      debugPrint('[4] Preparing atomic Firestore batch.');

      final batch = firestore.batch();

      if (usernameSnapshot.exists) {
        debugPrint('[4] Queue DELETE: usernames/$usernameLower');

        batch.delete(usernameRef);
      }

      debugPrint('[4] Queue DELETE: viaggiatori/$uid');

      batch.delete(profileRef);

      debugPrint('[4] Committing Firestore deletion batch...');

      await batch.commit();

      debugPrint('[4] Firestore deletion batch committed successfully.');

      debugPrint('');
      debugPrint('[4] Verifying profile deletion...');

      final profileVerification = await profileRef.get();

      if (profileVerification.exists) {
        debugPrint('[4] ERROR: profile still exists after deletion.');
        debugPrint('[4] Firebase Auth WILL NOT be deleted.');

        throw StateError('User profile still exists after Firestore deletion.');
      }

      debugPrint('[4] Verified: viaggiatori/$uid no longer exists.');

      if (usernameSnapshot.exists) {
        debugPrint('[4] Verifying username index deletion...');

        final usernameVerification = await usernameRef.get();

        if (usernameVerification.exists) {
          debugPrint('[4] ERROR: username index still exists after deletion.');
          debugPrint('[4] Firebase Auth WILL NOT be deleted.');

          throw StateError(
            'Username index still exists after Firestore deletion.',
          );
        }

        debugPrint('[4] Verified: usernames/$usernameLower no longer exists.');
      } else {
        debugPrint('[4] Username index did not exist before deletion.');
      }

      debugPrint('[4] Firestore account data deletion verified successfully.');
    } catch (error, stackTrace) {
      debugPrint('');
      debugPrint('[ACCOUNT DELETE] FIRESTORE ERROR');
      debugPrint('[ACCOUNT DELETE] $error');
      debugPrint('[ACCOUNT DELETE] $stackTrace');
      debugPrint('[ACCOUNT DELETE] Firebase Auth deletion NOT executed.');
      debugPrint('[ACCOUNT DELETE] PROCESS FAILED');
      debugPrint('==========================================');
      debugPrint('');

      rethrow;
    }

    debugPrint('');
    debugPrint('[5] FIREBASE AUTH');
    debugPrint('[5] All confirmed Firestore account data has been deleted.');
    debugPrint('[5] Deleting Firebase Auth user: $uid');

    try {
      await user.delete();

      debugPrint('[5] Firebase Auth user deleted successfully.');

      final currentUserAfterDeletion = auth.currentUser;

      debugPrint(
        '[5] Firebase Auth currentUser after deletion: '
        '${currentUserAfterDeletion?.uid ?? 'null'}',
      );

      if (currentUserAfterDeletion != null) {
        debugPrint(
          '[5] WARNING: FirebaseAuth.currentUser is not null '
          'after user.delete().',
        );
      }
    } on FirebaseAuthException catch (error, stackTrace) {
      debugPrint('');
      debugPrint('[ACCOUNT DELETE] FIREBASE AUTH ERROR');
      debugPrint('[ACCOUNT DELETE] Code: ${error.code}');
      debugPrint('[ACCOUNT DELETE] Message: ${error.message ?? 'null'}');
      debugPrint('[ACCOUNT DELETE] $stackTrace');
      debugPrint('[ACCOUNT DELETE] Firestore data was already deleted.');
      debugPrint(
        '[ACCOUNT DELETE] Firebase Auth user was NOT confirmed deleted.',
      );
      debugPrint('[ACCOUNT DELETE] PROCESS FAILED');
      debugPrint('==========================================');
      debugPrint('');

      rethrow;
    } catch (error, stackTrace) {
      debugPrint('');
      debugPrint('[ACCOUNT DELETE] FIREBASE AUTH ERROR');
      debugPrint('[ACCOUNT DELETE] $error');
      debugPrint('[ACCOUNT DELETE] $stackTrace');
      debugPrint('[ACCOUNT DELETE] Firestore data was already deleted.');
      debugPrint(
        '[ACCOUNT DELETE] Firebase Auth user was NOT confirmed deleted.',
      );
      debugPrint('[ACCOUNT DELETE] PROCESS FAILED');
      debugPrint('==========================================');
      debugPrint('');

      rethrow;
    }

    debugPrint('');
    debugPrint('[6] LOCAL DATA');
    debugPrint('[6] Clearing local remember-me data...');

    try {
      await RememberMeStorage.clear();

      debugPrint('[6] Remember-me data cleared successfully.');

      final rememberMeAfterClear = await RememberMeStorage.load();

      debugPrint('[6] Remember-me value after clear: $rememberMeAfterClear');

      if (rememberMeAfterClear) {
        debugPrint('[6] WARNING: remember-me is still true after clear.');
      } else {
        debugPrint('[6] Verified: remember-me is no longer enabled.');
      }
    } catch (error, stackTrace) {
      debugPrint('');
      debugPrint('[6] LOCAL DATA CLEANUP ERROR');
      debugPrint('[6] $error');
      debugPrint('[6] $stackTrace');
      debugPrint('[6] WARNING: Firebase account has already been deleted.');
      debugPrint(
        '[6] Local cleanup failure will NOT restore the deleted account.',
      );
    }

    debugPrint('');
    debugPrint('[7] NAVIGATION');
    debugPrint('[7] Navigation is handled outside AccountDeletionService.');

    debugPrint('');
    debugPrint('==========================================');
    debugPrint('[ACCOUNT DELETE] REAL DELETION COMPLETED');
    debugPrint('[ACCOUNT DELETE] FIRESTORE DATA DELETED');
    debugPrint('[ACCOUNT DELETE] FIREBASE AUTH USER DELETED');
    debugPrint('==========================================');
    debugPrint('');
  }

  static Future<void> runDryRun() async {
    final user = FirebaseAuth.instance.currentUser;

    debugPrint('');
    debugPrint('==========================================');
    debugPrint('[ACCOUNT DELETE] DRY RUN START');
    debugPrint('==========================================');

    if (user == null) {
      debugPrint('[ACCOUNT DELETE] ERROR: no authenticated user');
      debugPrint('==========================================');
      debugPrint('');
      return;
    }

    final providerIds = user.providerData
        .map((provider) => provider.providerId)
        .toList();

    debugPrint('[ACCOUNT DELETE] UID: ${user.uid}');
    debugPrint('[ACCOUNT DELETE] Email: ${user.email ?? 'null'}');
    debugPrint('[ACCOUNT DELETE] Providers: ${providerIds.join(', ')}');

    debugPrint('');
    debugPrint('[1] REAUTHENTICATION');

    if (providerIds.contains('password')) {
      debugPrint('[1] Password provider detected.');
      debugPrint('[1] Would request current password and reauthenticate user.');
    } else if (providerIds.contains('google.com')) {
      debugPrint('[1] Google provider detected.');
      debugPrint('[1] Would reauthenticate user with Google.');
    } else {
      debugPrint('[1] Other provider detected.');
      debugPrint('[1] Would use provider-specific reauthentication.');
    }

    debugPrint('[1] DRY RUN: reauthentication simulated OK');

    await Future<void>.delayed(const Duration(milliseconds: 200));

    debugPrint('');
    debugPrint('[2] GROUPS / TRIPS REFERENCES');
    debugPrint('[2] Would search for references to UID ${user.uid}.');
    debugPrint('[2] Would remove user from shared groups and trips.');
    debugPrint('[2] DRY RUN: no Firestore document modified.');

    await Future<void>.delayed(const Duration(milliseconds: 200));

    debugPrint('');
    debugPrint('[3] USER-OWNED DATA');
    debugPrint('[3] Would search for data owned by UID ${user.uid}.');
    debugPrint('[3] Would delete user-owned Firestore data.');
    debugPrint('[3] DRY RUN: no Firestore document deleted.');

    await Future<void>.delayed(const Duration(milliseconds: 200));

    debugPrint('');
    debugPrint('[4] USER PROFILE');

    try {
      final profileSnapshot = await FirebaseFirestore.instance
          .collection('viaggiatori')
          .doc(user.uid)
          .get();

      if (!profileSnapshot.exists) {
        debugPrint('[4] Profile not found: viaggiatori/${user.uid}.');
        debugPrint('[4] No username index can be resolved from the profile.');
      } else {
        debugPrint('[4] Profile found: viaggiatori/${user.uid}.');

        final profileData = profileSnapshot.data();
        final usernameLower = profileData?['usernameLower'] as String?;

        if (usernameLower == null || usernameLower.trim().isEmpty) {
          debugPrint('[4] WARNING: usernameLower missing from user profile.');
          debugPrint('[4] Username index cannot be verified.');
        } else {
          debugPrint('[4] usernameLower: $usernameLower');

          final usernameSnapshot = await FirebaseFirestore.instance
              .collection('usernames')
              .doc(usernameLower)
              .get();

          if (!usernameSnapshot.exists) {
            debugPrint(
              '[4] Username index not found: usernames/$usernameLower.',
            );
          } else {
            debugPrint('[4] Username index found: usernames/$usernameLower.');

            final usernameData = usernameSnapshot.data();
            final indexedUid = usernameData?['uid'] as String?;

            if (indexedUid == user.uid) {
              debugPrint('[4] Username index UID matches current user.');
            } else {
              debugPrint(
                '[4] WARNING: username index UID does not match '
                'current user.',
              );
              debugPrint('[4] Current UID: ${user.uid}');
              debugPrint('[4] Indexed UID: ${indexedUid ?? 'null'}');
            }
          }
        }

        debugPrint(
          '[4] Would delete this profile during real account deletion.',
        );
      }

      debugPrint('[4] DRY RUN: profile not deleted.');
      debugPrint('[4] DRY RUN: username index not deleted.');
    } catch (error) {
      debugPrint('[4] ERROR while reading profile or username index: $error');
      debugPrint(
        '[4] In a real deletion this would stop the process '
        'before Firebase Auth deletion.',
      );

      rethrow;
    }

    await Future<void>.delayed(const Duration(milliseconds: 200));

    debugPrint('');
    debugPrint('[5] FIREBASE AUTH');
    debugPrint('[5] Would delete Firebase Auth user ${user.uid}.');
    debugPrint('[5] DRY RUN: Firebase Auth user not deleted.');

    await Future<void>.delayed(const Duration(milliseconds: 200));

    debugPrint('');
    debugPrint('[6] LOCAL DATA');
    debugPrint('[6] Would clear remember-me and account-local data.');
    debugPrint('[6] DRY RUN: local data not cleared.');

    await Future<void>.delayed(const Duration(milliseconds: 200));

    debugPrint('');
    debugPrint('[7] NAVIGATION');
    debugPrint('[7] Would redirect user to login route "/".');
    debugPrint('[7] DRY RUN: no navigation performed.');

    debugPrint('');
    debugPrint('==========================================');
    debugPrint('[ACCOUNT DELETE] DRY RUN COMPLETED');
    debugPrint('[ACCOUNT DELETE] NO DATA WAS MODIFIED');
    debugPrint('==========================================');
    debugPrint('');
  }
}
