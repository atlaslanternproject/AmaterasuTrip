import 'permission_service.dart';

import 'platform/permission_service_unsupported.dart'
    if (dart.library.io) 'platform/permission_service_native.dart'
    if (dart.library.js_interop) 'platform/permission_service_web.dart'
    as platform;

PermissionService createPermissionService() {
  return platform.createPermissionService();
}
