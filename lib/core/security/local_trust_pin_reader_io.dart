import 'package:flutter/foundation.dart';

import 'android_first_device_trust_pin_storage.dart';

Future<bool> readLocalTrustPin(String uid) async {
  if (defaultTargetPlatform != TargetPlatform.android) {
    throw UnsupportedError('Android required.');
  }

  return await AndroidFirstDeviceTrustPinStorage().readPin(uid: uid) != null;
}
