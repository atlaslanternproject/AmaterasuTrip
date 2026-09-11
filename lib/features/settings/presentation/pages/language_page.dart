import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amaterasutrip/features/settings/providers/language_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(languageProvider);
    final supportedLocales = AppLocalizations.supportedLocales;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsLanguage),
      ),
      body: RadioGroup<Locale>(
        groupValue: currentLocale,
        onChanged: (locale) {
          if (locale == null) {
            return;
          }
          ref
            .read(languageProvider.notifier)
            .setLanguage(locale);
        },
        child: ListView.builder(
          itemCount: supportedLocales.length,
          itemBuilder: (context, index) {
            final locale = supportedLocales[index];
            return RadioListTile<Locale>(
              value: locale,
              title: Text(
                l10n.settingsLanguageName(
                  locale.languageCode,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}