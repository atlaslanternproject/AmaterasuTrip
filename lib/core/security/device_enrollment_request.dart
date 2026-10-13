import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'device_approval_signature.dart';

/// Public enrollment request transferred directly between devices.
///
/// The QR must be scanned from the requesting device itself.
/// This request is not an authorization or a trusted Firebase record.
class DeviceEnrollmentRequest {
  DeviceEnrollmentRequest._({
    required this.userUid,
    required this.newDeviceId,
    required List<int> x25519PublicKey,
    required List<int> ed25519PublicKey,
    required List<int> challenge,
    required this.issuedAtMs,
    required this.expiresAtMs,
  }) : x25519PublicKey = List<int>.unmodifiable(x25519PublicKey),
       ed25519PublicKey = List<int>.unmodifiable(ed25519PublicKey),
       challenge = List<int>.unmodifiable(challenge);

  static const qrPrefix = 'amaterasu-enroll-v1:';
  static const maximumQrLength = 1500;
  static const lifetimeMs = 3 * 60 * 1000;
  static const allowedClockSkewMs = 30 * 1000;

  final String userUid;
  final String newDeviceId;
  final List<int> x25519PublicKey;
  final List<int> ed25519PublicKey;
  final List<int> challenge;
  final int issuedAtMs;
  final int expiresAtMs;

  static Future<DeviceEnrollmentRequest> create({
    required String userUid,
    required String newDeviceId,
    required List<int> x25519PublicKey,
    required List<int> ed25519PublicKey,
    DateTime? nowUtc,
  }) async {
    final now = (nowUtc ?? DateTime.now()).toUtc();

    // Cryptographically secure 32-byte random challenge.
    final randomKey = await AesGcm.with256bits().newSecretKey();
    final challenge = await randomKey.extractBytes();

    final request = DeviceEnrollmentRequest._(
      userUid: userUid,
      newDeviceId: newDeviceId,
      x25519PublicKey: x25519PublicKey,
      ed25519PublicKey: ed25519PublicKey,
      challenge: challenge,
      issuedAtMs: now.millisecondsSinceEpoch,
      expiresAtMs: now.millisecondsSinceEpoch + lifetimeMs,
    );

    request._validateShape();
    return request;
  }

  String toQrPayload() {
    _validateShape();

    final bytes = utf8.encode(
      jsonEncode([
        'amaterasutrip',
        'device-enrollment',
        1,
        userUid,
        newDeviceId,
        base64Encode(x25519PublicKey),
        base64Encode(ed25519PublicKey),
        base64Encode(challenge),
        issuedAtMs,
        expiresAtMs,
      ]),
    );

    final payload = '$qrPrefix${base64UrlEncode(bytes).replaceAll('=', '')}';

    if (payload.length > maximumQrLength) {
      throw const FormatException('Enrollment QR is too large.');
    }

    return payload;
  }

  static DeviceEnrollmentRequest fromQrPayload(
    String payload, {
    required String expectedUserUid,
    required DateTime nowUtc,
  }) {
    if (!payload.startsWith(qrPrefix) || payload.length > maximumQrLength) {
      throw const FormatException('Invalid enrollment QR prefix or size.');
    }

    late final List<dynamic> data;

    try {
      final encoded = payload.substring(qrPrefix.length);
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(encoded))),
      );

      if (decoded is! List || decoded.length != 10) {
        throw const FormatException('Invalid enrollment QR structure.');
      }

      data = decoded;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid enrollment QR encoding.');
    }

    if (data[0] != 'amaterasutrip' ||
        data[1] != 'device-enrollment' ||
        data[2] != 1 ||
        data[3] is! String ||
        data[4] is! String ||
        data[5] is! String ||
        data[6] is! String ||
        data[7] is! String ||
        data[8] is! int ||
        data[9] is! int) {
      throw const FormatException('Unsupported enrollment QR format.');
    }

    late final DeviceEnrollmentRequest request;

    try {
      request = DeviceEnrollmentRequest._(
        userUid: data[3] as String,
        newDeviceId: data[4] as String,
        x25519PublicKey: base64Decode(data[5] as String),
        ed25519PublicKey: base64Decode(data[6] as String),
        challenge: base64Decode(data[7] as String),
        issuedAtMs: data[8] as int,
        expiresAtMs: data[9] as int,
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid enrollment key encoding.');
    }

    request._validateShape();

    if (request.userUid != expectedUserUid) {
      throw StateError('Enrollment belongs to a different account.');
    }

    final now = nowUtc.toUtc().millisecondsSinceEpoch;

    if (now >= request.expiresAtMs ||
        request.issuedAtMs > now + allowedClockSkewMs) {
      throw StateError('Enrollment request expired or not yet valid.');
    }

    return request;
  }

  DeviceApprovalClaim toApprovalClaim({required String approverDeviceId}) {
    _validateShape();

    return DeviceApprovalClaim(
      userUid: userUid,
      approverDeviceId: approverDeviceId,
      newDeviceId: newDeviceId,
      newX25519PublicKey: x25519PublicKey,
      newEd25519PublicKey: ed25519PublicKey,
      challenge: challenge,
      issuedAtMs: issuedAtMs,
      expiresAtMs: expiresAtMs,
    );
  }

  void _validateShape() {
    for (final identifier in [userUid, newDeviceId]) {
      if (identifier.trim().isEmpty ||
          identifier.length > 128 ||
          identifier.codeUnits.any((code) => code < 32)) {
        throw const FormatException('Invalid enrollment identifier.');
      }
    }

    for (final value in [x25519PublicKey, ed25519PublicKey, challenge]) {
      if (value.length != 32 ||
          value.any((byte) => byte < 0 || byte > 255) ||
          value.every((byte) => byte == 0)) {
        throw const FormatException('Invalid enrollment key or challenge.');
      }
    }

    final duration = expiresAtMs - issuedAtMs;

    if (issuedAtMs <= 0 || duration <= 0 || duration > lifetimeMs) {
      throw const FormatException('Invalid enrollment lifetime.');
    }
  }
}
