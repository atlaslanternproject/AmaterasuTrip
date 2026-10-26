import 'package:amaterasutrip/core/permissions/app_permission.dart';
import 'package:amaterasutrip/core/permissions/permission_result.dart';
import 'package:amaterasutrip/core/permissions/platform/permission_service_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebPermissionService', () {
    final service = WebPermissionService();

    test('delegates camera permission handling to the browser flow', () async {
      final result = await service.request(AppPermission.camera);

      expect(result, AppPermissionResult.granted);
    });

    test('delegates photo permission handling to the browser flow', () async {
      final result = await service.request(AppPermission.photos);

      expect(result, AppPermissionResult.granted);
    });

    test('does not expose native app settings', () async {
      final result = await service.openSettings();

      expect(result, isFalse);
    });
  });
}
