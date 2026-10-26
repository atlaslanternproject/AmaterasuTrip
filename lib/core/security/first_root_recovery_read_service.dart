import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'first_root_local_identity.dart';
import 'first_root_recovery_record.dart';

/// Read-only recovery preflight. Never enrolls a browser.
final class FirstRootRecoveryReadService {
  Future<FirstRootLocalIdentity> recover({required String recoveryCode}) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !user.emailVerified) {
      throw StateError('Verified authentication required.');
    }

    final token = await user.getIdTokenResult(true);
    final authTime = token.authTime;

    if (authTime == null ||
        DateTime.now().toUtc().difference(authTime.toUtc()).abs() >
            const Duration(minutes: 5)) {
      throw StateError('Recent authentication required.');
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('e2eeRoots')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server));

    final data = snapshot.data();
    if (data == null) {
      throw StateError('No registered recovery identity.');
    }

    final record = FirstRootRecoveryRecord.fromServer(
      uid: user.uid,
      data: data,
    );

    // The recovered private keys remain in client memory.
    // No local persistence or device approval happens here.
    return record.recover(recoveryCode);
  }
}
