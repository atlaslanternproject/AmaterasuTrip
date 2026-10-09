import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'permission_service.dart';
import 'permission_service_factory.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return createPermissionService();
});
