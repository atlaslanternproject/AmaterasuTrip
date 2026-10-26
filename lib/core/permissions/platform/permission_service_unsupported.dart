import '../app_permission.dart';
import '../permission_result.dart';
import '../permission_service.dart';

PermissionService createPermissionService() {
  return UnsupportedPermissionService();
}

class UnsupportedPermissionService implements PermissionService {
  @override
  Future<AppPermissionResult> request(AppPermission permission) async {
    return AppPermissionResult.denied;
  }

  @override
  Future<bool> openSettings() async {
    return false;
  }
}
