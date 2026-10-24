/// Android/native: B10.3 already serializes same-isolate calls.
/// This stub does not claim cross-process atomicity.
Future<T> withPendingRecoveryDeviceLock<T>(
  String uid,
  Future<T> Function() action,
) {
  return action();
}
