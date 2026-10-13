import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Encrypted payload only. Never add plaintext health fields here.
class EncryptedTravellerProfile {
  const EncryptedTravellerProfile({
    required this.nonce,
    required this.ciphertext,
    required this.mac,
  });

  static const int formatVersion = 1;
  static const String algorithm = 'AES-256-GCM';

  final String nonce;
  final String ciphertext;
  final String mac;

  Map<String, dynamic> toMap() => {
    'version': formatVersion,
    'algorithm': algorithm,
    'nonce': nonce,
    'ciphertext': ciphertext,
    'mac': mac,
  };

  factory EncryptedTravellerProfile.fromMap(Map<String, dynamic> data) {
    if (data['version'] != formatVersion ||
        data['algorithm'] != algorithm ||
        data['nonce'] is! String ||
        data['ciphertext'] is! String ||
        data['mac'] is! String) {
      throw const FormatException(
        'Unsupported encrypted traveller profile format.',
      );
    }

    return EncryptedTravellerProfile(
      nonce: data['nonce'] as String,
      ciphertext: data['ciphertext'] as String,
      mac: data['mac'] as String,
    );
  }
}

/// Isolated cryptographic primitive.
///
/// Does not persist keys, contact Firebase, or modify existing profiles.
/// Secure key distribution and recovery must be implemented separately.
class TravellerProfileCipher {
  final AesGcm _algorithm = AesGcm.with256bits();

  Future<SecretKey> generateProfileKey() {
    return _algorithm.newSecretKey();
  }

  Future<EncryptedTravellerProfile> encrypt({
    required Map<String, dynamic> sensitiveFields,
    required SecretKey secretKey,
    required String tripId,
    required String memberUid,
  }) async {
    final aad = _associatedData(tripId, memberUid);

    final plaintext = utf8.encode(jsonEncode(sensitiveFields));

    final box = await _algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: _algorithm.newNonce(),
      aad: aad,
    );

    return EncryptedTravellerProfile(
      nonce: base64Encode(box.nonce),
      ciphertext: base64Encode(box.cipherText),
      mac: base64Encode(box.mac.bytes),
    );
  }

  Future<Map<String, dynamic>> decrypt({
    required EncryptedTravellerProfile encrypted,
    required SecretKey secretKey,
    required String tripId,
    required String memberUid,
  }) async {
    final aad = _associatedData(tripId, memberUid);

    final nonce = base64Decode(encrypted.nonce);
    final ciphertext = base64Decode(encrypted.ciphertext);
    final mac = base64Decode(encrypted.mac);

    if (nonce.length != _algorithm.nonceLength ||
        mac.length != _algorithm.macAlgorithm.macLength) {
      throw const FormatException('Invalid encrypted profile envelope.');
    }

    final box = SecretBox(ciphertext, nonce: nonce, mac: Mac(mac));

    final plaintext = await _algorithm.decrypt(
      box,
      secretKey: secretKey,
      aad: aad,
    );

    final decoded = jsonDecode(utf8.decode(plaintext));

    if (decoded is! Map) {
      throw const FormatException('Invalid decrypted traveller profile.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  List<int> _associatedData(String tripId, String memberUid) {
    if (tripId.trim().isEmpty || memberUid.trim().isEmpty) {
      throw ArgumentError('Trip ID and member UID are required.');
    }

    return utf8.encode(
      jsonEncode([
        'amaterasutrip',
        'traveller-profile',
        EncryptedTravellerProfile.formatVersion,
        tripId,
        memberUid,
      ]),
    );
  }
}
