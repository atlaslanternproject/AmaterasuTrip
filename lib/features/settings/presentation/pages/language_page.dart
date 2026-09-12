import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amaterasutrip/features/settings/providers/language_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_primary_button.dart';
class LanguagePage extends ConsumerStatefulWidget {
  const LanguagePage({super.key});
  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _cardColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);
  @override
  ConsumerState<LanguagePage> createState() => _LanguagePageState();
}
class _LanguagePageState extends ConsumerState<LanguagePage> {
  late Locale _selectedLocale;
  @override
  void initState() {
    super.initState();
    _selectedLocale = ref.read(languageProvider);
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(languageProvider);
    final supportedLocales = AppLocalizations.supportedLocales;

    return Scaffold(
      backgroundColor: LanguagePage._backgroundColor,
      appBar: AppBar(
        backgroundColor: LanguagePage._backgroundColor,
        elevation: 0,
        title: Text(
          l10n.settingsLanguage,
          style: const TextStyle(
            color: LanguagePage._titleColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              itemCount: supportedLocales.length,
              itemBuilder: (context, index) {
                final locale = supportedLocales[index];
                final isSelected = locale == _selectedLocale;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == supportedLocales.length - 1 ? 0 : 10,
                  ),
                  child: _LanguageCard(
                    title: l10n.settingsLanguageName(
                      locale.languageCode,
                    ),
                    locale: locale,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedLocale = locale;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: AmaterasuPrimaryButton(
              text: l10n.confirm,
              onPressed: _selectedLocale == currentLocale
                  ? null
                  : () {
                      ref
                          .read(languageProvider.notifier)
                          .setLanguage(_selectedLocale);
                    },
            ),
          ),
        ],
      ),
    );
  }
}
class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.title,
    required this.locale,
    required this.isSelected,
    required this.onTap,
  });
  final String title;
  final Locale locale;
  final bool isSelected;
  final VoidCallback onTap;
  static const Map<String, String> _languageFlags = {
    'it': '🇮🇹',
    'en': '🇬🇧',
  };
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: LanguagePage._cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? LanguagePage._accentColor.withValues(alpha: 0.75)
                  : LanguagePage._borderColor,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? LanguagePage._accentColor.withValues(alpha: 0.75)
                          : LanguagePage._borderColor,
                    ),
                  ),
                  child: Text(
                    _languageFlags[locale.languageCode] ?? '🌐',
                    style: const TextStyle(
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: LanguagePage._titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? LanguagePage._accentColor
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? LanguagePage._accentColor
                          : LanguagePage._subtitleColor,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: LanguagePage._backgroundColor,
                          size: 18,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}