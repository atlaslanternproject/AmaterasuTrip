import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class WrappedTravellerProfileKey {
  const WrappedTravellerProfileKey({
    required this.salt,
    required this.nonce,
    required this.ciphertext,
    required this.mac,
  });

  static const version = 1;
  static const algorithm = 'HKDF-SHA256-AES256-GCM';

  final String salt;
  final String nonce;
  final String ciphertext;
  final String mac;

  Map<String, dynamic> toMap() => {
    'version': version,
    'algorithm': algorithm,
    'salt': salt,
    'nonce': nonce,
    'ciphertext': ciphertext,
    'mac': mac,
  };

  factory WrappedTravellerProfileKey.fromMap(Map<String, dynamic> map) {
    if (map['version'] != version ||
        map['algorithm'] != algorithm ||
        map['salt'] is! String ||
        map['nonce'] is! String ||
        map['ciphertext'] is! String ||
        map['mac'] is! String) {
      throw const FormatException('Invalid key envelope.');
    }

    return WrappedTravellerProfileKey(
      salt: map['salt'] as String,
      nonce: map['nonce'] as String,
      ciphertext: map['ciphertext'] as String,
      mac: map['mac'] as String,
    );
  }
}

/// Experimental key wrapping primitive.
///
/// Authentication of device public keys, access control, rotation and
/// replay protection must be implemented before production integration.
class TravellerProfileKeyWrap {
  final AesGcm _aes = AesGcm.with256bits();

  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  Future<WrappedTravellerProfileKey> wrap({
    required List<int> sharedSecret,
    required List<int> profileKey,
    required String tripId,
    required String profileUid,
    required String senderDeviceId,
    required String recipientDeviceId,
  }) async {
    _validateKey(sharedSecret, 'X25519 shared secret');
    _validateKey(profileKey, 'Profile key');

    final context = _context(
      tripId,
      profileUid,
      senderDeviceId,
      recipientDeviceId,
    );

    // A freshly generated 256-bit random value used as HKDF salt.
    final salt = await (await _aes.newSecretKey()).extractBytes();

    final wrappingKey = await _derive(sharedSecret, salt, context);

    final box = await _aes.encrypt(
      profileKey,
      secretKey: wrappingKey,
      nonce: _aes.newNonce(),
      aad: context,
    );

    return WrappedTravellerProfileKey(
      salt: base64Encode(salt),
      nonce: base64Encode(box.nonce),
      ciphertext: base64Encode(box.cipherText),
      mac: base64Encode(box.mac.bytes),
    );
  }

  Future<List<int>> unwrap({
    required WrappedTravellerProfileKey envelope,
    required List<int> sharedSecret,
    required String tripId,
    required String profileUid,
    required String senderDeviceId,
    required String recipientDeviceId,
  }) async {
    _validateKey(sharedSecret, 'X25519 shared secret');

    final context = _context(
      tripId,
      profileUid,
      senderDeviceId,
      recipientDeviceId,
    );

    final salt = base64Decode(envelope.salt);
    final nonce = base64Decode(envelope.nonce);
    final ciphertext = base64Decode(envelope.ciphertext);
    final mac = base64Decode(envelope.mac);

    if (salt.length != 32 ||
        nonce.length != _aes.nonceLength ||
        mac.length != _aes.macAlgorithm.macLength) {
      throw const FormatException('Invalid key envelope lengths.');
    }

    final wrappingKey = await _derive(sharedSecret, salt, context);

    final bytes = await _aes.decrypt(
      SecretBox(ciphertext, nonce: nonce, mac: Mac(mac)),
      secretKey: wrappingKey,
      aad: context,
    );

    _validateKey(bytes, 'Decrypted profile key');
    return bytes;
  }

  Future<SecretKey> _derive(
    List<int> sharedSecret,
    List<int> salt,
    List<int> context,
  ) {
    return _hkdf.deriveKey(
      secretKey: SecretKey(sharedSecret),
      nonce: salt,
      info: context,
    );
  }

  List<int> _context(
    String tripId,
    String profileUid,
    String senderDeviceId,
    String recipientDeviceId,
  ) {
    final values = [tripId, profileUid, senderDeviceId, recipientDeviceId];

    if (values.any((value) => value.trim().isEmpty)) {
      throw ArgumentError('All key wrapping identifiers are required.');
    }

    return utf8.encode(
      jsonEncode([
        'amaterasutrip',
        'traveller-profile-key-wrap',
        WrappedTravellerProfileKey.version,
        ...values,
      ]),
    );
  }

  void _validateKey(List<int> bytes, String name) {
    if (bytes.length != 32 || bytes.any((b) => b < 0 || b > 255)) {
      throw ArgumentError('$name must contain exactly 32 valid bytes.');
    }
  }
}
