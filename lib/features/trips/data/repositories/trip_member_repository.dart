import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cryptography/cryptography.dart';
import 'package:amaterasutrip/core/security/personal_profile_key_vault.dart';
import 'package:amaterasutrip/core/security/traveller_health_transport_codec.dart';
import 'package:amaterasutrip/core/security/verified_trip_profile_sessions.dart';
import 'package:amaterasutrip/features/trips/data/security/trip_traveller_e2ee_bridge.dart';

import 'package:amaterasutrip/features/trips/models/trip_member.dart';

class TripMemberRemovalResult {
  const TripMemberRemovalResult({
    required this.removed,
    required this.leftTrip,
  });

  final bool removed;
  final bool leftTrip;
}

class TripMemberRepository {
  TripMemberRepository(this._functions);

  final FirebaseFunctions _functions;

  Future<List<TripMember>> getMembers(String tripId) async {
    final callable = _functions.httpsCallable('listTripMembers');

    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
    });

    final rawMembers = result.data['members'];

    if (rawMembers is! List) {
      throw StateError('Invalid listTripMembers response.');
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      throw StateError('Sign-in is required to unlock trip profiles.');
    }

    final members = <TripMember>[];
    for (final raw in rawMembers) {
      if (raw is! Map) {
        throw StateError('Invalid trip member data.');
      }
      final data = Map<String, dynamic>.from(raw);
      final memberUid = data['uid'];
      if (memberUid is! String || memberUid.isEmpty) {
        throw StateError('Invalid trip member identity.');
      }

      final format = data['travellerProfileFormat'];
      final transport = data['travellerProfile'];

      // Never expose an unverified questionnaire.
      // Membership metadata remains separately readable.
      data['travellerProfile'] = null;
      var sensitiveProfileLocked = true;

      if (format == 'encrypted' && transport is Map) {
        final encrypted = Map<String, dynamic>.from(transport);

        if (memberUid == currentUid) {
          final vault = PersonalProfileKeyVault();

          try {
            final candidates = await vault.candidates(currentUid, tripId);

            for (final candidate in candidates) {
              try {
                final decoded = await TripTravellerE2eeBridge().openMember(
                  transport: encrypted,
                  profileKey: candidate.key,
                  tripId: tripId,
                  memberUid: memberUid,
                );

                data['travellerProfile'] = decoded.toMap();
                sensitiveProfileLocked = false;

                if (candidate.pending) {
                  await vault.promote(currentUid, tripId, candidate.key);
                }
                break;
              } catch (_) {
                // Try the next locally held key.
              }
            }
          } catch (_) {
            // Never expose undecrypted sensitive data.
          }
        }

        if (sensitiveProfileLocked) {
          try {
            final lease = await VerifiedTripProfileSessions.instance
                .requireLease(
                  tripId: tripId,
                  profileUid: memberUid,
                  currentUserUid: currentUid,
                );

            final key = await lease.requireKey(
              tripId: tripId,
              profileUid: memberUid,
              currentUserUid: currentUid,
            );

            final decoded = await TripTravellerE2eeBridge().openMember(
              transport: encrypted,
              profileKey: key,
              tripId: tripId,
              memberUid: memberUid,
            );

            data['travellerProfile'] = decoded.toMap();
            sensitiveProfileLocked = false;
          } catch (_) {
            // Untrusted or unavailable keys never unlock the profile.
          }
        }
      } else if (format == 'missing' && transport == null) {
        sensitiveProfileLocked = false;
      } else if (format == 'legacy-redacted') {
        // Legacy questionnaire remains inaccessible.
      }

      // Unknown formats and old plaintext responses remain locked.
      data['sensitiveProfileLocked'] = sensitiveProfileLocked;
      members.add(TripMember.fromMap(data));
    }

    members.sort((a, b) {
      if (a.isAdmin != b.isAdmin) {
        return a.isAdmin ? -1 : 1;
      }

      final aJoined = a.joinedAt;
      final bJoined = b.joinedAt;

      if (aJoined == null && bJoined == null) {
        return a.uid.compareTo(b.uid);
      }

      if (aJoined == null) {
        return 1;
      }

      if (bJoined == null) {
        return -1;
      }

      return aJoined.compareTo(bJoined);
    });

    return members;
  }

  /// Blocks legacy plaintext updates before any Cloud Function call.
  Future<void> updateMyTravellerProfile({
    required String tripId,
    required TripTravellerProfileData profile,
  }) async {
    throw StateError(
      'E2EE device setup is required before saving a questionnaire.',
    );
  }

  /// Requires a key already trusted and available on the local device.
  /// The UI must not call this before device/key enrolment is completed.
  Future<void> updateMyTravellerProfileEncrypted({
    required String tripId,
    required TripTravellerProfileData profile,
    required VerifiedTripProfileKeyLease verifiedSession,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign-in is required to encrypt a questionnaire.');
    }

    final profileKey = await verifiedSession.requireKey(
      tripId: tripId,
      profileUid: uid,
      currentUserUid: uid,
    );

    final envelope = await TravellerHealthTransportCodec().seal(
      profile: profile.toMap(),
      profileKey: profileKey,
      tripId: tripId,
      memberUid: uid,
    );

    final callable = _functions.httpsCallable('updateMyTripTravellerProfile');
    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
      'travellerProfile': envelope,
    });

    if (result.data['updated'] != true) {
      throw StateError('Invalid updateMyTripTravellerProfile response.');
    }
  }

  /// This UID owns its own questionnaire, regardless of trip role.
  /// No second authentication. No self-approval QR.
  Future<String?> saveMyPersonalProfile({
    required String tripId,
    required TripMember member,
    required TripTravellerProfileData profile,
    required bool replaceLocked,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid != member.uid) {
      throw StateError('Only the profile owner can save these answers.');
    }

    final revision = member.profileRevision;

    if (revision == null) {
      throw StateError('The server did not provide a profile revision.');
    }

    if (member.sensitiveProfileLocked && !replaceLocked) {
      throw StateError('Unlock or explicitly recompile this profile.');
    }

    final vault = PersonalProfileKeyVault();
    SecretKey key;
    var staged = false;

    if (replaceLocked) {
      key = await vault.stageNew(uid, tripId);
      staged = true;
    } else {
      final active = await vault.active(uid, tripId);

      if (active != null) {
        key = active;
      } else {
        final pending = await vault.pending(uid, tripId);

        if (pending != null) {
          key = pending;
          staged = true;
        } else if (member.profileFormat == 'missing') {
          key = await vault.stageNew(uid, tripId);
          staged = true;
        } else {
          final lease = await VerifiedTripProfileSessions.instance.requireLease(
            tripId: tripId,
            profileUid: uid,
            currentUserUid: uid,
          );

          key = await lease.requireKey(
            tripId: tripId,
            profileUid: uid,
            currentUserUid: uid,
          );

          await vault.stageExisting(uid, tripId, key);
          staged = true;
        }
      }
    }

    final encrypted = await TravellerHealthTransportCodec().seal(
      profile: profile.toMap(),
      profileKey: key,
      tripId: tripId,
      memberUid: uid,
    );

    final response = await _functions
        .httpsCallable('updateMyTripTravellerProfile')
        .call<Map<String, dynamic>>({
          'tripId': tripId,
          'travellerProfile': encrypted,
          'expectedProfileRevision': revision,
          'replaceLockedProfile': replaceLocked,
        });

    if (response.data['updated'] != true || response.data['uid'] != uid) {
      throw StateError('The encrypted questionnaire was not confirmed.');
    }

    // The old active key is untouched until Firebase confirms success.
    if (staged) {
      await vault.promote(uid, tripId, key);
    }

    // Display after a new key is created or after a replacement.
    return (staged || replaceLocked)
        ? await vault.exportCode(uid, tripId, key)
        : null;
  }

  Future<void> recoverMyPersonalProfile({
    required String tripId,
    required String recoveryCode,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign-in required.');
    }

    final vault = PersonalProfileKeyVault();
    final candidate = vault.parseCode(recoveryCode, uid, tripId);

    final response = await _functions
        .httpsCallable('listTripMembers')
        .call<Map<String, dynamic>>({'tripId': tripId});

    final raw = response.data['members'];
    if (raw is! List) {
      throw StateError('Invalid member list.');
    }

    Map<String, dynamic>? mine;

    for (final element in raw) {
      if (element is Map && element['uid'] == uid) {
        mine = Map<String, dynamic>.from(element);
        break;
      }
    }

    if (mine == null ||
        mine['travellerProfileFormat'] != 'encrypted' ||
        mine['travellerProfile'] is! Map) {
      throw StateError('No encrypted questionnaire to recover.');
    }

    // The recovery key is accepted only if it really decrypts
    // the current server-side ciphertext.
    await TripTravellerE2eeBridge().openMember(
      transport: Map<String, dynamic>.from(mine['travellerProfile'] as Map),
      profileKey: candidate,
      tripId: tripId,
      memberUid: uid,
    );

    await vault.promote(uid, tripId, candidate);
  }

  Future<String> myRecoveryCode(String tripId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      throw StateError('Sign-in required.');
    }

    final vault = PersonalProfileKeyVault();
    final active = await vault.active(uid, tripId);

    if (active == null) {
      throw StateError('No local profile key available.');
    }

    return vault.exportCode(uid, tripId, active);
  }

  Future<TripMemberRemovalResult> removeMember({
    required String tripId,
    required String targetUid,
  }) async {
    final callable = _functions.httpsCallable('removeTripMember');

    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
      'targetUid': targetUid,
    });

    final data = result.data;

    if (data['removed'] != true) {
      throw StateError('Invalid removeTripMember response.');
    }

    // Any membership change invalidates the local roster/key leases.
    // This is not a substitute for server-side signed key rotation.
    VerifiedTripProfileSessions.instance.clearTrip(tripId);

    return TripMemberRemovalResult(
      removed: true,
      leftTrip: data['leftTrip'] == true,
    );
  }
}
