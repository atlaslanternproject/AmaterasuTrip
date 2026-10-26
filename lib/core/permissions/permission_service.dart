import 'app_permission.dart';
import 'permission_result.dart';

abstract interface class PermissionService {
  Future<AppPermissionResult> request(AppPermission permission);

  Future<bool> openSettings();
}
