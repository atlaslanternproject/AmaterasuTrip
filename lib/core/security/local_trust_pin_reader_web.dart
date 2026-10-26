import 'web_first_device_trust_pin_storage.dart';

Future<bool> readLocalTrustPin(String uid) async {
  final store = await WebFirstDeviceTrustPinStorage.open();

  try {
    return await store.readPin(userUid: uid) != null;
  } finally {
    store.close();
  }
}
