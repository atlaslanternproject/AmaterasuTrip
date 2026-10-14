import 'first_device_trust_anchor.dart';
import 'android_first_device_trust_pin_storage.dart';

Future<({String deviceId, String fingerprint})?> readRootPin(String uid) async {
  final saved = await AndroidFirstDeviceTrustPinStorage().readPin(uid: uid);

  if (saved == null) return null;

  return (deviceId: saved.deviceId, fingerprint: saved.fingerprint);
}

Future<void> pinRoot(SignedFirstDeviceTrustAnchor signed) async {
  throw UnsupportedError(
    'Use pinLocallyIssuedRoot with the original local signing key.',
  );
}
