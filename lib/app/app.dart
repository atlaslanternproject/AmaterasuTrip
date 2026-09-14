import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/profile/providers/user_provider.dart';
import '../features/settings/providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

class AmaterasuTripApp extends ConsumerStatefulWidget {
  const AmaterasuTripApp({super.key});

  @override
  ConsumerState<AmaterasuTripApp> createState() => _AmaterasuTripAppState();
}

class _AmaterasuTripAppState extends ConsumerState<AmaterasuTripApp> {
  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recoverPendingProfilePhoto();
    });
  }

  Future<void> _recoverPendingProfilePhoto() async {
    final recoveryService = ref.read(
      profilePhotoRecoveryServiceProvider,
    );

    final isPending = await recoveryService.isPending();

    if (!isPending) {
      return;
    }

    final picker = ref.read(
      profilePhotoPickerServiceProvider,
    );

    try {
      final recoveredPhoto = await picker.retrieveLostPhoto();

      if (recoveredPhoto == null) {
        await recoveryService.clearRecovery();
        return;
      }

      await recoveryService.saveRecoveredPath(
        recoveredPhoto.path,
      );

      await recoveryService.clearPending();

      debugPrint(
        'Recovered profile photo: ${recoveredPhoto.path}',
      );

      amaterasuRouter.go('/settings/profile');
    } catch (error, stackTrace) {
      debugPrint(
        'Profile photo recovery failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      await recoveryService.clearRecovery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'AmaterasuTrip',
      theme: appTheme,
      routerConfig: amaterasuRouter,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}