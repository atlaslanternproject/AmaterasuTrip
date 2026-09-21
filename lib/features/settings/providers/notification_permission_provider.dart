import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final notificationPermissionProvider =
    AsyncNotifierProvider<NotificationPermissionNotifier, PermissionStatus>(
      NotificationPermissionNotifier.new,
    );

class NotificationPermissionNotifier extends AsyncNotifier<PermissionStatus> {
  @override
  Future<PermissionStatus> build() async {
    return Permission.notification.status;
  }

  Future<PermissionStatus> requestPermission() async {
    final status = await Permission.notification.request();

    state = AsyncData(status);

    return status;
  }

  Future<void> refreshStatus() async {
    final status = await Permission.notification.status;

    state = AsyncData(status);
  }

  Future<bool> openSettings() async {
    return openAppSettings();
  }
}
