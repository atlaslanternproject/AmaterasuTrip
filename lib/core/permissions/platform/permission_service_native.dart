import 'package:permission_handler/permission_handler.dart';

import '../app_permission.dart';
import '../permission_result.dart';
import '../permission_service.dart';

PermissionService createPermissionService() {
  return NativePermissionService();
}

class NativePermissionService implements PermissionService {
  @override
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
    return switch (permission) {
      AppPermission.camera => Permission.camera,
      AppPermission.photos => Permission.photos,
    };
  }

  @override
  Future<bool> openSettings() {
    return openAppSettings();
  }
}
