import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

class InformationLicensesPage extends StatefulWidget {
  const InformationLicensesPage({super.key});

  @override
  State<InformationLicensesPage> createState() =>
      _InformationLicensesPageState();
}

class _InformationLicensesPageState extends State<InformationLicensesPage> {
  final List<LicenseEntry> _licenses = [];
  bool _loading = true;

  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _sectionColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    final licenses = <LicenseEntry>[];

    await for (final license in LicenseRegistry.licenses) {
      licenses.add(license);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _licenses
        ..clear()
        ..addAll(licenses);

      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: Text(
          l10n.informationOpenSourceLicenses,
          style: const TextStyle(
            color: _titleColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: _accentColor,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: _licenses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final license = _licenses[index];
                final packages = license.packages.toList()..sort();

                return Container(
                  decoration: BoxDecoration(
                    color: _sectionColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _borderColor,
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            color: _accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              packages.join(', '),
                              style: const TextStyle(
                                color: _titleColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...license.paragraphs.map(
                        (paragraph) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            paragraph.text,
                            style: const TextStyle(
                              color: _subtitleColor,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
