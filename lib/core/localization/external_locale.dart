import 'dart:ui';

class ExternalLocale {
  const ExternalLocale._();

  static const Set<String> supportedLanguages = {
    'it',
    'en',
  };

  static String get languageCode {
    final systemLanguageCode =
        PlatformDispatcher.instance.locale.languageCode.toLowerCase();

    if (supportedLanguages.contains(systemLanguageCode)) {
      return systemLanguageCode;
    }

    return 'en';
  }
}