import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class PersonalProfileKeyCandidate {
  const PersonalProfileKeyCandidate(this.key, this.pending);

  final SecretKey key;
  final bool pending;
}

/// Secure local storage for the authenticated user's own trip profile.
/// Firebase Auth identifies the account; it does not supply encryption keys.
final class PersonalProfileKeyVault {
  PersonalProfileKeyVault();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _slot(String uid, String tripId, String kind) {
    if (uid.isEmpty ||
        tripId.isEmpty ||
        uid.length > 128 ||
        tripId.length > 256) {
      throw ArgumentError('Invalid profile identity.');
    }

    final u = base64UrlEncode(utf8.encode(uid));
    final t = base64UrlEncode(utf8.encode(tripId));

    return 'amaterasu:personal-e2ee:v1:$kind:$u:$t';
  }

  Future<SecretKey?> _read(String uid, String tripId, String kind) async {
    final encoded = await _storage.read(key: _slot(uid, tripId, kind));

    if (encoded == null) return null;

    final bytes = base64Decode(encoded);

    if (bytes.length != 32) {
      throw const FormatException('Invalid local AES-256 key.');
    }

    return SecretKey(bytes);
  }

  Future<void> _write(
    String uid,
    String tripId,
    String kind,
    SecretKey key,
  ) async {
    final bytes = await key.extractBytes();

    if (bytes.length != 32) {
      throw ArgumentError('Expected AES-256 key.');
    }

    final encoded = base64Encode(bytes);
    final slot = _slot(uid, tripId, kind);

    await _storage.write(key: slot, value: encoded);

    if (await _storage.read(key: slot) != encoded) {
      throw StateError('Secure key persistence failed.');
    }
  }

  Future<SecretKey?> active(String uid, String tripId) =>
      _read(uid, tripId, 'active');

  Future<SecretKey?> pending(String uid, String tripId) =>
      _read(uid, tripId, 'pending');

  Future<List<PersonalProfileKeyCandidate>> candidates(
    String uid,
    String tripId,
  ) async {
    final result = <PersonalProfileKeyCandidate>[];

    final current = await active(uid, tripId);
    if (current != null) {
      result.add(PersonalProfileKeyCandidate(current, false));
    }

    final staged = await pending(uid, tripId);
    if (staged != null) {
      result.add(PersonalProfileKeyCandidate(staged, true));
    }

    return result;
  }

  Future<SecretKey> stageNew(String uid, String tripId) async {
    final existing = await pending(uid, tripId);
    if (existing != null) return existing;

    final candidate = await AesGcm.with256bits().newSecretKey();

    // Persist separately before attempting the remote write.
    // The active key is never overwritten by staging.
    await _write(uid, tripId, 'pending', candidate);

    return candidate;
  }

  Future<void> stageExisting(String uid, String tripId, SecretKey key) =>
      _write(uid, tripId, 'pending', key);

  Future<void> promote(
    String uid,
    String tripId,
    SecretKey confirmedKey,
  ) async {
    final previous = await active(uid, tripId);

    if (previous != null) {
      final oldBytes = await previous.extractBytes();
      final newBytes = await confirmedKey.extractBytes();

      if (base64Encode(oldBytes) != base64Encode(newBytes)) {
        // Retain an old local key if a confirmed new revision replaces it.
        final stamp = DateTime.now().toUtc().millisecondsSinceEpoch.toString();

        await _write(uid, tripId, 'previous-$stamp', previous);
      }
    }

    await _write(uid, tripId, 'active', confirmedKey);

    // Delete pending only after active storage has been verified.
    await _storage.delete(key: _slot(uid, tripId, 'pending'));
  }

  Future<String> exportCode(String uid, String tripId, SecretKey key) async {
    final raw = await key.extractBytes();

    if (raw.length != 32) {
      throw StateError('Invalid recovery material.');
    }

    String encode(List<int> value) =>
        base64UrlEncode(value).replaceAll('=', '');

    return 'AT-PROFILE-1.'
        '${encode(utf8.encode(uid))}.'
        '${encode(utf8.encode(tripId))}.'
        '${encode(raw)}';
  }

  SecretKey parseCode(String code, String uid, String tripId) {
    final parts = code.trim().split('.');

    if (parts.length != 4 || parts[0] != 'AT-PROFILE-1') {
      throw const FormatException('Invalid profile recovery code.');
    }

    List<int> decode(String value) =>
        base64Url.decode(base64Url.normalize(value));

    final codeUid = utf8.decode(decode(parts[1]));
    final codeTripId = utf8.decode(decode(parts[2]));
    final keyBytes = decode(parts[3]);

    if (codeUid != uid || codeTripId != tripId || keyBytes.length != 32) {
      throw StateError('Recovery code does not match this profile.');
    }

    return SecretKey(keyBytes);
  }
}
