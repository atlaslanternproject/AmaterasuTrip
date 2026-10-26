import '../app_permission.dart';
import '../permission_result.dart';
import '../permission_service.dart';

PermissionService createPermissionService() {
  return WebPermissionService();
}

class WebPermissionService implements PermissionService {
  @override
  Future<AppPermissionResult> request(AppPermission permission) async {
    return AppPermissionResult.granted;
  }

  @override
  Future<bool> openSettings() async {
    return false;
  }
}
