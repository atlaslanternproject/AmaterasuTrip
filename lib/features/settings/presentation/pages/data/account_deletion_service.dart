import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AccountDeletionService {
  const AccountDeletionService._();

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
    debugPrint(
      '[ACCOUNT DELETE] Providers: ${providerIds.join(', ')}',
    );

    debugPrint('');
    debugPrint('[1] REAUTHENTICATION');

    if (providerIds.contains('password')) {
      debugPrint('[1] Password provider detected.');
      debugPrint(
        '[1] Would request current password and reauthenticate user.',
      );
    } else if (providerIds.contains('google.com')) {
      debugPrint('[1] Google provider detected.');
      debugPrint(
        '[1] Would reauthenticate user with Google.',
      );
    } else {
      debugPrint('[1] Other provider detected.');
      debugPrint(
        '[1] Would use provider-specific reauthentication.',
      );
    }

    debugPrint('[1] DRY RUN: reauthentication simulated OK');

    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );

    debugPrint('');
    debugPrint('[2] GROUPS / TRIPS REFERENCES');
    debugPrint(
      '[2] Would search for references to UID ${user.uid}.',
    );
    debugPrint(
      '[2] Would remove user from shared groups and trips.',
    );
    debugPrint(
      '[2] DRY RUN: no Firestore document modified.',
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );

    debugPrint('');
    debugPrint('[3] USER-OWNED DATA');
    debugPrint(
      '[3] Would search for data owned by UID ${user.uid}.',
    );
    debugPrint(
      '[3] Would delete user-owned Firestore data.',
    );
    debugPrint(
      '[3] DRY RUN: no Firestore document deleted.',
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );

    debugPrint('');
    debugPrint('[4] USER PROFILE');

    try {
      final profileSnapshot = await FirebaseFirestore.instance
          .collection('viaggiatori')
          .doc(user.uid)
          .get();

      if (!profileSnapshot.exists) {
        debugPrint(
          '[4] Profile not found: viaggiatori/${user.uid}.',
        );
        debugPrint(
          '[4] No username index can be resolved from the profile.',
        );
      } else {
        debugPrint(
          '[4] Profile found: viaggiatori/${user.uid}.',
        );

        final profileData = profileSnapshot.data();
        final usernameLower = profileData?['usernameLower'] as String?;

        if (usernameLower == null || usernameLower.trim().isEmpty) {
          debugPrint(
            '[4] WARNING: usernameLower missing from user profile.',
          );
          debugPrint(
            '[4] Username index cannot be verified.',
          );
        } else {
          debugPrint(
            '[4] usernameLower: $usernameLower',
          );

          final usernameSnapshot = await FirebaseFirestore.instance
              .collection('usernames')
              .doc(usernameLower)
              .get();

          if (!usernameSnapshot.exists) {
            debugPrint(
              '[4] Username index not found: usernames/$usernameLower.',
            );
          } else {
            debugPrint(
              '[4] Username index found: usernames/$usernameLower.',
            );

            final usernameData = usernameSnapshot.data();
            final indexedUid = usernameData?['uid'] as String?;

            if (indexedUid == user.uid) {
              debugPrint(
                '[4] Username index UID matches current user.',
              );
            } else {
              debugPrint(
                '[4] WARNING: username index UID does not match '
                'current user.',
              );
              debugPrint(
                '[4] Current UID: ${user.uid}',
              );
              debugPrint(
                '[4] Indexed UID: ${indexedUid ?? 'null'}',
              );
            }
          }
        }

        debugPrint(
          '[4] Would delete this profile during real account deletion.',
        );
      }

      debugPrint(
        '[4] DRY RUN: profile not deleted.',
      );
      debugPrint(
        '[4] DRY RUN: username index not deleted.',
      );
    } catch (error) {
      debugPrint(
        '[4] ERROR while reading profile or username index: $error',
      );
      debugPrint(
        '[4] In a real deletion this would stop the process '
        'before Firebase Auth deletion.',
      );

      rethrow;
    }

    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );

    debugPrint('');
    debugPrint('[5] FIREBASE AUTH');
    debugPrint(
      '[5] Would delete Firebase Auth user ${user.uid}.',
    );
    debugPrint(
      '[5] DRY RUN: Firebase Auth user not deleted.',
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );

    debugPrint('');
    debugPrint('[6] LOCAL DATA');
    debugPrint(
      '[6] Would clear remember-me and account-local data.',
    );
    debugPrint(
      '[6] DRY RUN: local data not cleared.',
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );

    debugPrint('');
    debugPrint('[7] NAVIGATION');
    debugPrint(
      '[7] Would redirect user to login route "/".',
    );
    debugPrint(
      '[7] DRY RUN: no navigation performed.',
    );

    debugPrint('');
    debugPrint('==========================================');
    debugPrint('[ACCOUNT DELETE] DRY RUN COMPLETED');
    debugPrint('[ACCOUNT DELETE] NO DATA WAS MODIFIED');
    debugPrint('==========================================');
    debugPrint('');
  }
}