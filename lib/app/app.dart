import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../features/settings/providers/language_provider.dart';
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