import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final notificationPermissionProvider =
    AsyncNotifierProvider<NotificationPermissionNotifier, PermissionStatus>(
      NotificationPermissionNotifier.new,
    );

class NotificationPermissionNotifier extends AsyncNotifier<PermissionStatus> {
  @override
  Future<PermissionStatus> build() async {
    if (kIsWeb) {
      return PermissionStatus.denied;
    }

    return Permission.notification.status;
  }

  Future<PermissionStatus> requestPermission() async {
    final status = kIsWeb
        ? PermissionStatus.denied
        : await Permission.notification.request();

    state = AsyncData(status);

    return status;
  }

  Future<void> refreshStatus() async {
    final status = kIsWeb
        ? PermissionStatus.denied
        : await Permission.notification.status;

    state = AsyncData(status);
  }

  Future<bool> openSettings() async {
    if (kIsWeb) {
      return false;
    }

    return openAppSettings();
  }
}
