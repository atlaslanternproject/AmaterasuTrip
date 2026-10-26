import 'package:cryptography/cryptography.dart';

import 'traveller_profile_cipher.dart';

/// Experimental transport adapter. Not connected to production repositories.
///
/// Callers must supply an independently authorised and securely managed key.
/// Never fall back to plaintext if encryption or decryption fails.
class TravellerHealthTransportCodec {
  TravellerHealthTransportCodec({TravellerProfileCipher? cipher})
    : _cipher = cipher ?? TravellerProfileCipher();

  final TravellerProfileCipher _cipher;

  static const _publicFields = <String>{
    'hasEsimOrInternet',
    'hasCheckedBaggage',
    'hasCabinBaggage10Kg',
  };

  static const _sensitiveBooleans = <String>{
    'hasAllergies',
    'hasIntolerances',
    'hasMedicalAccessibilityInfo',
  };

  static const _sensitiveTexts = <String>{
    'allergies',
    'intolerances',
    'medicalAccessibilityInfo',
    'emergencyContactName',
    'emergencyContactPhone',
  };

  static const _envelopeFields = <String>{
    'version',
    'algorithm',
    'nonce',
    'ciphertext',
    'mac',
  };

  void _requireExactKeys(Map<String, dynamic> data, Set<String> expected) {
    final actual = data.keys.toSet();
    if (actual.length != expected.length || !actual.containsAll(expected)) {
      throw const FormatException('Invalid traveller profile structure.');
    }
  }

  void _validateProfile(Map<String, dynamic> profile) {
    _requireExactKeys(profile, {
      ..._publicFields,
      ..._sensitiveBooleans,
      ..._sensitiveTexts,
    });

    for (final field in {..._publicFields, ..._sensitiveBooleans}) {
      final value = profile[field];
      if (value != null && value is! bool) {
        throw const FormatException('Invalid traveller profile answer.');
      }
    }

    for (final field in _sensitiveTexts) {
      if (profile[field] is! String) {
        throw const FormatException('Invalid traveller profile text.');
      }
    }
  }

  /// Builds a transport object containing no plaintext sensitive fields.
  Future<Map<String, dynamic>> seal({
    required Map<String, dynamic> profile,
    required SecretKey profileKey,
    required String tripId,
    required String memberUid,
  }) async {
    _validateProfile(profile);

    final sensitive = <String, dynamic>{
      for (final field in _publicFields) field: profile[field],
      for (final field in _sensitiveBooleans) field: profile[field],
      for (final field in _sensitiveTexts) field: profile[field],
    };

    final encrypted = await _cipher.encrypt(
      sensitiveFields: sensitive,
      secretKey: profileKey,
      tripId: tripId,
      memberUid: memberUid,
    );

    return <String, dynamic>{
      for (final field in _publicFields) field: profile[field],
      'protectedDetails': encrypted.toMap(),
    };
  }

  /// Returns plaintext only to a caller holding the authorised key.
  Future<Map<String, dynamic>> open({
    required Map<String, dynamic> transport,
    required SecretKey profileKey,
    required String tripId,
    required String memberUid,
  }) async {
    _requireExactKeys(transport, {..._publicFields, 'protectedDetails'});

    for (final field in _publicFields) {
      final value = transport[field];
      if (value != null && value is! bool) {
        throw const FormatException('Invalid public profile answer.');
      }
    }

    final rawEnvelope = transport['protectedDetails'];
    if (rawEnvelope is! Map) {
      throw const FormatException('Missing encrypted details.');
    }

    final envelopeMap = Map<String, dynamic>.from(rawEnvelope);
    _requireExactKeys(envelopeMap, _envelopeFields);

    final encrypted = EncryptedTravellerProfile.fromMap(envelopeMap);

    final sensitive = await _cipher.decrypt(
      encrypted: encrypted,
      secretKey: profileKey,
      tripId: tripId,
      memberUid: memberUid,
    );

    _requireExactKeys(sensitive, {
      ..._publicFields,
      ..._sensitiveBooleans,
      ..._sensitiveTexts,
    });

    for (final field in _publicFields) {
      if (sensitive[field] != transport[field]) {
        throw const FormatException('Authenticated public profile mismatch.');
      }
    }
    final profile = <String, dynamic>{
      for (final field in _publicFields) field: transport[field],
      ...sensitive,
    };

    _validateProfile(profile);
    return profile;
  }
}
