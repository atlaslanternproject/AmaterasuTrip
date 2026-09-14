import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import 'app_permission.dart';
import 'permission_result.dart';

class PermissionService {
  Future<AppPermissionResult> request(AppPermission permission) async {
    final platformPermission = _resolvePermission(permission);

    var status = await platformPermission.status;

    if (status.isGranted || status.isLimited) {
      return AppPermissionResult.granted;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      return AppPermissionResult.permanentlyDenied;
    }

    status = await platformPermission.request();

    if (status.isGranted || status.isLimited) {
      return AppPermissionResult.granted;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      return AppPermissionResult.permanentlyDenied;
    }

    return AppPermissionResult.denied;
  }

  Permission _resolvePermission(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return Permission.camera;

      case AppPermission.photos:
        if (Platform.isAndroid) {
          return Permission.photos;
        }

        return Permission.photos;
    }
  }

  Future<bool> openSettings() {
    return openAppSettings();
  }
}
