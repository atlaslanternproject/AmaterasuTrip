import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// A new, still-untrusted recovery device.
/// This is never the original root identity.
final class PendingRecoveryDeviceIdentity {
  PendingRecoveryDeviceIdentity({
    required this.uid,
    required this.deviceId,
    required this.createdAtMs,
    required List<int> exchangePrivate,
    required List<int> exchangePublic,
    required List<int> signingPrivate,
    required List<int> signingPublic,
  }) : exchangePrivate = List<int>.unmodifiable(exchangePrivate),
       exchangePublic = List<int>.unmodifiable(exchangePublic),
       signingPrivate = List<int>.unmodifiable(signingPrivate),
       signingPublic = List<int>.unmodifiable(signingPublic);

  final String uid;
  final String deviceId;
  final int createdAtMs;

  final List<int> exchangePrivate;
  final List<int> exchangePublic;
  final List<int> signingPrivate;
  final List<int> signingPublic;

  static void validateUid(String uid) {
    if (uid.trim().isEmpty ||
        uid.length > 128 ||
        uid.codeUnits.any((value) => value < 32)) {
      throw ArgumentError('Invalid account UID.');
    }
  }

  static Future<PendingRecoveryDeviceIdentity> generate(String uid) async {
    validateUid(uid);

    final exchange = await X25519().newKeyPair();
    final signing = await Ed25519().newKeyPair();
    final random = await AesGcm.with256bits().newSecretKey();

    final deviceId = base64UrlEncode(
      await random.extractBytes(),
    ).replaceAll('=', '');

    return PendingRecoveryDeviceIdentity(
      uid: uid,
      deviceId: deviceId,
      createdAtMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      exchangePrivate: await exchange.extractPrivateKeyBytes(),
      exchangePublic: (await exchange.extractPublicKey()).bytes,
      signingPrivate: await signing.extractPrivateKeyBytes(),
      signingPublic: (await signing.extractPublicKey()).bytes,
    );
  }

  /// Local storage representation. Never send this to Firebase.
  String encodeLocally() => jsonEncode({
    'version': 1,
    'uid': uid,
    'deviceId': deviceId,
    'createdAtMs': createdAtMs,
    'exchangePrivate': base64Encode(exchangePrivate),
    'exchangePublic': base64Encode(exchangePublic),
    'signingPrivate': base64Encode(signingPrivate),
    'signingPublic': base64Encode(signingPublic),
  });

  static Future<PendingRecoveryDeviceIdentity> decodeLocal(
    String raw, {
    required String expectedUid,
  }) async {
    validateUid(expectedUid);

    if (raw.length > 4096) {
      throw const FormatException('Oversized local identity.');
    }

    final decoded = jsonDecode(raw);

    if (decoded is! Map<String, dynamic> ||
        decoded.length != 8 ||
        decoded['version'] != 1 ||
        decoded['uid'] != expectedUid ||
        decoded['deviceId'] is! String ||
        decoded['createdAtMs'] is! int) {
      throw const FormatException('Invalid pending device identity.');
    }

    List<int> key(String field) {
      final value = decoded[field];

      if (value is! String) {
        throw const FormatException('Missing device key.');
      }

      final bytes = base64Decode(value);

      if (bytes.length != 32) {
        throw const FormatException('Invalid device key length.');
      }

      return bytes;
    }

    final identity = PendingRecoveryDeviceIdentity(
      uid: expectedUid,
      deviceId: decoded['deviceId'] as String,
      createdAtMs: decoded['createdAtMs'] as int,
      exchangePrivate: key('exchangePrivate'),
      exchangePublic: key('exchangePublic'),
      signingPrivate: key('signingPrivate'),
      signingPublic: key('signingPublic'),
    );

    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(identity.deviceId) ||
        identity.createdAtMs <= 0) {
      throw const FormatException('Invalid device identifier.');
    }

    final x = await X25519().newKeyPairFromSeed(identity.exchangePrivate);
    final ed = await Ed25519().newKeyPairFromSeed(identity.signingPrivate);

    if (!_same((await x.extractPublicKey()).bytes, identity.exchangePublic) ||
        !_same((await ed.extractPublicKey()).bytes, identity.signingPublic)) {
      throw const FormatException('Local device key mismatch.');
    }

    return identity;
  }

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }

    return difference == 0;
  }
}
