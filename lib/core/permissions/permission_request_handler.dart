import 'package:flutter/material.dart';

import 'app_permission.dart';
import 'permission_result.dart';
import 'permission_service.dart';

Future<bool> requestAppPermission({
  required BuildContext context,
  required PermissionService permissionService,
  required AppPermission permission,
  required String deniedMessage,
  required String permanentlyDeniedMessage,
  required String openSettingsLabel,
}) async {
  final result = await permissionService.request(permission);

  if (!context.mounted) {
    return false;
  }

  switch (result) {
    case AppPermissionResult.granted:
      return true;

    case AppPermissionResult.denied:
      final messenger = ScaffoldMessenger.of(context);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(deniedMessage),
          ),
        );

      return false;

    case AppPermissionResult.permanentlyDenied:
      final messenger = ScaffoldMessenger.of(context);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(permanentlyDeniedMessage),
            action: SnackBarAction(
              label: openSettingsLabel,
              onPressed: permissionService.openSettings,
            ),
          ),
        );

      return false;
  }
}
