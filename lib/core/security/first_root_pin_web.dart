import 'first_device_trust_anchor.dart';
import 'web_first_device_trust_pin_storage.dart';

Future<({String deviceId, String fingerprint})?> readRootPin(String uid) async {
  final store = await WebFirstDeviceTrustPinStorage.open();
  try {
    final saved = await store.readPin(userUid: uid);
    if (saved == null) return null;
    return (deviceId: saved.deviceId, fingerprint: saved.fingerprint);
  } finally {
    store.close();
  }
}

Future<void> pinRoot(SignedFirstDeviceTrustAnchor signed) async {
  final store = await WebFirstDeviceTrustPinStorage.open();
  try {
    final fingerprint = await FirstDeviceTrustAnchorService().fingerprint(
      signed.anchor,
    );
    await store.pinVerifiedRoot(
      signed: signed,
      independentlyTrustedFingerprint: fingerprint,
    );
  } finally {
    store.close();
  }
}
