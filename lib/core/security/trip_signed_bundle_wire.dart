import 'dart:convert';

import 'authenticated_profile_key_exchange.dart';
import 'signed_trip_device_roster.dart';
import 'traveller_profile_key_rotation.dart';
import 'traveller_profile_key_wrap.dart';

/// Untrusted transport package.
///
/// Parsing and structural checks NEVER authenticate the sender,
/// establish a trust pin, update an epoch or unlock a profile.
final class UntrustedSignedTripBundle {
  const UntrustedSignedTripBundle({
    required this.roster,
    required this.rotation,
  });

  final SignedTripDeviceRoster roster;
  final SignedProfileKeyRotation rotation;
}

/// Exact, bounded JSON transport for signed E2EE bundles.
///
/// Only signed ciphertext, encrypted grants and public identities
/// are serialised. No health plaintext or private keys are allowed.
///
/// Always pass decoded values through VerifiedTripProfileSessions
/// with independently pinned identities and trusted epoch storage.
final class TripSignedBundleWire {
  static const version = 1;
  static const maximumBytes = 262144;

  static Map<String, dynamic> encode({
    required SignedTripDeviceRoster roster,
    required SignedProfileKeyRotation rotation,
  }) {
    final result = <String, dynamic>{
      'version': version,
      'roster': <String, dynamic>{
        'tripId': roster.tripId,
        'authorityUid': roster.authorityUid,
        'authorityDeviceId': roster.authorityDeviceId,
        'epoch': roster.epoch,
        'activeDevices': [
          for (final device in roster.activeDevices)
            {
              'uid': device.uid,
              'deviceId': device.deviceId,
              'x25519Fingerprint': device.x25519Fingerprint,
              'ed25519PublicKey': base64Encode(device.ed25519PublicKeyBytes),
            },
        ],
        'revokedMemberUids': [...roster.revokedMemberUids],
        'signature': base64Encode(roster.signatureBytes),
      },
      'rotation': <String, dynamic>{
        'tripId': rotation.tripId,
        'profileUid': rotation.profileUid,
        'senderDeviceId': rotation.senderDeviceId,
        'epoch': rotation.epoch,
        'encryptedProfile': Map<String, dynamic>.from(
          rotation.encryptedProfile,
        ),
        'grants': [
          for (final grant in rotation.grants)
            {
              'tripId': grant.tripId,
              'profileUid': grant.profileUid,
              'senderUid': grant.senderUid,
              'recipientUid': grant.recipientUid,
              'senderDeviceId': grant.senderDeviceId,
              'recipientDeviceId': grant.recipientDeviceId,
              'keyEpoch': grant.keyEpoch,
              'senderX25519PublicKey': base64Encode(
                grant.senderX25519PublicKey,
              ),
              'recipientX25519PublicKey': base64Encode(
                grant.recipientX25519PublicKey,
              ),
              'wrappedKey': grant.wrappedKey.toMap(),
              'signature': base64Encode(grant.signatureBytes),
            },
        ],
        'revokedMemberUids': [...rotation.revokedMemberUids],
        'signature': base64Encode(rotation.signatureBytes),
      },
    };

    // Validate the outgoing package too, without assuming it is trusted.
    decodeUntrusted(result);
    return result;
  }

  static UntrustedSignedTripBundle decodeUntrusted(Object? input) {
    final root = _map(input, {'version', 'roster', 'rotation'});

    if (root['version'] != version) {
      throw const FormatException('Unsupported E2EE wire version.');
    }

    final size = utf8.encode(jsonEncode(root)).length;

    if (size > maximumBytes) {
      throw const FormatException('E2EE wire package too large.');
    }

    final roster = _readRoster(root['roster']);
    final rotation = _readRotation(root['rotation']);

    if (roster.tripId != rotation.tripId ||
        roster.epoch != rotation.epoch ||
        !_same(roster.revokedMemberUids, rotation.revokedMemberUids)) {
      throw const FormatException('Inconsistent E2EE bundle.');
    }

    final identities = <String>{
      for (final device in roster.activeDevices)
        jsonEncode([device.uid, device.deviceId]),
    };

    final granted = <String>{
      for (final grant in rotation.grants)
        jsonEncode([grant.recipientUid, grant.recipientDeviceId]),
    };

    if (identities.length != roster.activeDevices.length ||
        granted.length != rotation.grants.length ||
        identities.length != granted.length ||
        !identities.containsAll(granted) ||
        !granted.containsAll(identities)) {
      throw const FormatException('E2EE recipient roster mismatch.');
    }

    if (!identities.contains(
      jsonEncode([rotation.profileUid, rotation.senderDeviceId]),
    )) {
      throw const FormatException('Missing profile signing device.');
    }

    return UntrustedSignedTripBundle(roster: roster, rotation: rotation);
  }

  static Map<String, dynamic> _map(Object? value, Set<String> fields) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw const FormatException('Invalid E2EE JSON object.');
    }

    final result = Map<String, dynamic>.from(value);

    if (result.length != fields.length ||
        !result.keys.toSet().containsAll(fields)) {
      throw const FormatException('Unexpected E2EE JSON fields.');
    }

    return result;
  }

  static List<dynamic> _list(Object? value, int max) {
    if (value is! List || value.isEmpty || value.length > max) {
      throw const FormatException('Invalid E2EE JSON list.');
    }
    return value;
  }

  static List<String> _strings(Object? value) {
    if (value is! List || value.length > 200) {
      throw const FormatException('Invalid E2EE identity list.');
    }

    return [
      for (final item in value)
        if (item is String && item.isNotEmpty)
          item
        else
          throw const FormatException('Invalid E2EE identity list.'),
    ];
  }

  static String _id(Object? value) {
    if (value is! String || value.trim().isEmpty || value.length > 512) {
      throw const FormatException('Invalid E2EE identity.');
    }
    return value;
  }

  static int _epoch(Object? value) {
    if (value is! int || value < 2 || value >= 2147483647) {
      throw const FormatException('Invalid trusted epoch.');
    }
    return value;
  }

  static List<int> _bytes(Object? value, int length) {
    if (value is! String) {
      throw const FormatException('Invalid E2EE base64.');
    }
    try {
      final result = base64Decode(value);
      if (result.length != length || base64Encode(result) != value) {
        throw const FormatException('Noncanonical E2EE base64.');
      }
      return result;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid E2EE bytes.');
    }
  }

  static SignedTripDeviceRoster _readRoster(Object? value) {
    final raw = _map(value, {
      'tripId',
      'authorityUid',
      'authorityDeviceId',
      'epoch',
      'activeDevices',
      'revokedMemberUids',
      'signature',
    });

    final devices = <RosterDevice>[];

    for (final item in _list(raw['activeDevices'], 200)) {
      final device = _map(item, {
        'uid',
        'deviceId',
        'x25519Fingerprint',
        'ed25519PublicKey',
      });

      devices.add(
        RosterDevice(
          uid: _id(device['uid']),
          deviceId: _id(device['deviceId']),
          x25519Fingerprint: _id(device['x25519Fingerprint']),
          ed25519PublicKeyBytes: _bytes(device['ed25519PublicKey'], 32),
        ),
      );
    }

    return SignedTripDeviceRoster(
      tripId: _id(raw['tripId']),
      authorityUid: _id(raw['authorityUid']),
      authorityDeviceId: _id(raw['authorityDeviceId']),
      epoch: _epoch(raw['epoch']),
      activeDevices: devices,
      revokedMemberUids: _strings(raw['revokedMemberUids']),
      signatureBytes: _bytes(raw['signature'], 64),
    );
  }

  static SignedTravellerProfileKeyGrant _readGrant(Object? value) {
    final raw = _map(value, {
      'tripId',
      'profileUid',
      'senderUid',
      'recipientUid',
      'senderDeviceId',
      'recipientDeviceId',
      'keyEpoch',
      'senderX25519PublicKey',
      'recipientX25519PublicKey',
      'wrappedKey',
      'signature',
    });

    final wrappedMap = _map(raw['wrappedKey'], {
      'version',
      'algorithm',
      'salt',
      'nonce',
      'ciphertext',
      'mac',
    });

    if (wrappedMap['version'] != WrappedTravellerProfileKey.version ||
        wrappedMap['algorithm'] != WrappedTravellerProfileKey.algorithm) {
      throw const FormatException('Invalid wrapped key version.');
    }

    _bytes(wrappedMap['salt'], 32);
    _bytes(wrappedMap['nonce'], 12);
    _bytes(wrappedMap['ciphertext'], 32);
    _bytes(wrappedMap['mac'], 16);

    return SignedTravellerProfileKeyGrant(
      tripId: _id(raw['tripId']),
      profileUid: _id(raw['profileUid']),
      senderUid: _id(raw['senderUid']),
      recipientUid: _id(raw['recipientUid']),
      senderDeviceId: _id(raw['senderDeviceId']),
      recipientDeviceId: _id(raw['recipientDeviceId']),
      keyEpoch: _epoch(raw['keyEpoch']),
      senderX25519PublicKey: _bytes(raw['senderX25519PublicKey'], 32),
      recipientX25519PublicKey: _bytes(raw['recipientX25519PublicKey'], 32),
      wrappedKey: WrappedTravellerProfileKey.fromMap(wrappedMap),
      signatureBytes: _bytes(raw['signature'], 64),
    );
  }

  static Map<String, dynamic> _encryptedProfile(Object? value) {
    final raw = _map(value, {
      'hasEsimOrInternet',
      'hasCheckedBaggage',
      'hasCabinBaggage10Kg',
      'protectedDetails',
    });

    for (final key in [
      'hasEsimOrInternet',
      'hasCheckedBaggage',
      'hasCabinBaggage10Kg',
    ]) {
      if (raw[key] != null && raw[key] is! bool) {
        throw const FormatException('Invalid public profile fields.');
      }
    }

    final envelope = _map(raw['protectedDetails'], {
      'version',
      'algorithm',
      'nonce',
      'ciphertext',
      'mac',
    });

    if (envelope['version'] != 1 || envelope['algorithm'] != 'AES-256-GCM') {
      throw const FormatException('Invalid encrypted profile format.');
    }

    _bytes(envelope['nonce'], 12);
    _bytes(envelope['mac'], 16);

    final ciphertext = envelope['ciphertext'];
    if (ciphertext is! String ||
        ciphertext.isEmpty ||
        ciphertext.length > 131072) {
      throw const FormatException('Invalid encrypted profile payload.');
    }

    try {
      final decoded = base64Decode(ciphertext);
      if (decoded.isEmpty || base64Encode(decoded) != ciphertext) {
        throw const FormatException('Invalid profile ciphertext.');
      }
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid profile ciphertext.');
    }

    return {...raw, 'protectedDetails': envelope};
  }

  static SignedProfileKeyRotation _readRotation(Object? value) {
    final raw = _map(value, {
      'tripId',
      'profileUid',
      'senderDeviceId',
      'epoch',
      'encryptedProfile',
      'grants',
      'revokedMemberUids',
      'signature',
    });

    final tripId = _id(raw['tripId']);
    final profileUid = _id(raw['profileUid']);
    final senderDeviceId = _id(raw['senderDeviceId']);
    final epoch = _epoch(raw['epoch']);
    final revoked = _strings(raw['revokedMemberUids']);

    final grants = <SignedTravellerProfileKeyGrant>[];

    for (final item in _list(raw['grants'], 200)) {
      final grant = _readGrant(item);

      if (grant.tripId != tripId ||
          grant.profileUid != profileUid ||
          grant.senderUid != profileUid ||
          grant.senderDeviceId != senderDeviceId ||
          grant.keyEpoch != epoch ||
          revoked.contains(grant.recipientUid)) {
        throw const FormatException('Inconsistent signed key grant.');
      }

      grants.add(grant);
    }

    return SignedProfileKeyRotation(
      tripId: tripId,
      profileUid: profileUid,
      senderDeviceId: senderDeviceId,
      epoch: epoch,
      encryptedProfile: _encryptedProfile(raw['encryptedProfile']),
      grants: grants,
      revokedMemberUids: revoked,
      signatureBytes: _bytes(raw['signature'], 64),
    );
  }

  static bool _same(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
