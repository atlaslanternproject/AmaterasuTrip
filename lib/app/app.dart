import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../features/settings/providers/language_provider.dart';
class AmaterasuTripApp extends ConsumerWidget {
  const AmaterasuTripApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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