import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Experimental offline recovery kit.
///
/// The encoded kit contains the recovery secret in reversible form.
/// Never send it to a backend, logs, analytics or support channels.
/// Its checksum detects transcription errors, NOT malicious replacement.
class AccountRecoveryKit {
  AccountRecoveryKit({
    required this.userUid,
    required this.rootFingerprint,
    required List<int> recoverySecret,
  }) : recoverySecret = List<int>.unmodifiable(recoverySecret);

  final String userUid;
  final String rootFingerprint;
  final List<int> recoverySecret;
}

class AccountRecoveryKitCodec {
  static const prefix = 'AMTR-REC-1';

  final Sha256 _sha256 = Sha256();

  Future<String> encode({
    required String userUid,
    required String rootFingerprint,
    required List<int> recoverySecret,
  }) async {
    _validate(userUid, rootFingerprint, recoverySecret);

    final secretText = base64UrlEncode(recoverySecret).replaceAll('=', '');

    final payload = base64UrlEncode(
      utf8.encode(jsonEncode([1, userUid, rootFingerprint, secretText])),
    ).replaceAll('=', '');

    final checksum = await _checksum(payload);
    return '$prefix.$payload.$checksum';
  }

  Future<AccountRecoveryKit> decode(String encoded) async {
    if (encoded.length > 1024 || encoded.trim() != encoded) {
      throw const FormatException('Invalid recovery kit.');
    }

    final parts = encoded.split('.');

    if (parts.length != 3 ||
        parts[0] != prefix ||
        !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(parts[1])) {
      throw const FormatException('Invalid recovery kit.');
    }

    final expectedChecksum = await _checksum(parts[1]);

    if (!_sameText(expectedChecksum, parts[2])) {
      throw const FormatException('Recovery kit checksum mismatch.');
    }

    try {
      final payloadBytes = base64Url.decode(base64Url.normalize(parts[1]));

      final payload = jsonDecode(utf8.decode(payloadBytes));

      if (payload is! List ||
          payload.length != 4 ||
          payload[0] != 1 ||
          payload[1] is! String ||
          payload[2] is! String ||
          payload[3] is! String) {
        throw const FormatException('Invalid recovery kit.');
      }

      final secretText = payload[3] as String;

      if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(secretText)) {
        throw const FormatException('Invalid recovery kit.');
      }

      final secret = base64Url.decode(base64Url.normalize(secretText));

      final uid = payload[1] as String;
      final root = payload[2] as String;

      _validate(uid, root, secret);

      final canonical = await encode(
        userUid: uid,
        rootFingerprint: root,
        recoverySecret: secret,
      );

      if (!_sameText(canonical, encoded)) {
        throw const FormatException('Non-canonical recovery kit.');
      }

      return AccountRecoveryKit(
        userUid: uid,
        rootFingerprint: root,
        recoverySecret: secret,
      );
    } catch (_) {
      throw const FormatException('Invalid recovery kit.');
    }
  }

  Future<String> _checksum(String payload) async {
    final digest = await _sha256.hash(utf8.encode('$prefix.$payload'));

    return base64UrlEncode(digest.bytes.take(8).toList()).replaceAll('=', '');
  }

  void _validate(String uid, String root, List<int> secret) {
    if (uid.trim().isEmpty ||
        uid.length > 128 ||
        uid.codeUnits.any((value) => value < 32) ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(root) ||
        secret.length != 32 ||
        secret.any((value) => value < 0 || value > 255)) {
      throw ArgumentError('Invalid recovery kit input.');
    }
  }

  bool _sameText(String first, String second) {
    if (first.length != second.length) return false;

    var difference = 0;

    for (var i = 0; i < first.length; i++) {
      difference |= first.codeUnitAt(i) ^ second.codeUnitAt(i);
    }

    return difference == 0;
  }
}
