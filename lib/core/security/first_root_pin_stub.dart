import 'first_device_trust_anchor.dart';

Future<({String deviceId, String fingerprint})?> readRootPin(String uid) async {
  throw UnsupportedError('Platform not supported.');
}

Future<void> pinRoot(SignedFirstDeviceTrustAnchor signed) async {
  throw UnsupportedError('Platform not supported.');
}
