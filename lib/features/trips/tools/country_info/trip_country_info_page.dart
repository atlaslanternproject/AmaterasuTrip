// Pagina "Info paese" di Altro (nuova tappa 1c): avviso "verifica sempre
// su fonti ufficiali", scelta del paese (parte da quello della
// destinazione), voci pratiche con fonte e schede ufficiali. Solo lettura
// di un file dell'app: nessuna API, nessun dato salvato.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_header.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_country_info_data.dart';
import 'trip_country_info_entries.dart';

class TripCountryInfoPage extends ConsumerStatefulWidget {
  const TripCountryInfoPage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripCountryInfoPage> createState() =>
      _TripCountryInfoPageState();
}

class _TripCountryInfoPageState extends ConsumerState<TripCountryInfoPage> {
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final book = ref.watch(tripCountryInfoBookProvider).asData?.value;
    final code = _picked ?? ref.watch(tripCountryCodeProvider(widget.tripId));
    final country = book?.countries[code];
    final sorted = [...?book?.countries.values]
      ..sort((a, b) => a.name(lang).compareTo(b.name(lang)));
    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      body: SafeArea(
        child: Column(
          children: [
            TripSectionHeader(
              tripId: widget.tripId,
              title: l10n.countryInfoTitle,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: book == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AmaterasuColors.primary,
                          ),
                        )
                      : ListView(
                          key: const Key('country-info-page'),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AmaterasuColors.accentGold,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.countryInfoVerify,
                                    key: const Key('country-info-verify'),
                                    style: const TextStyle(
                                      color: AmaterasuColors.accentGold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              key: const Key('country-info-select'),
                              initialValue: country?.code,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: l10n.countryInfoCountry,
                              ),
                              items: [
                                for (final c in sorted)
                                  DropdownMenuItem(
                                    value: c.code,
                                    child: Text(
                                      c.name(lang),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (v) => setState(() => _picked = v),
                            ),
                            const SizedBox(height: 12),
                            if (country == null)
                              Text(
                                l10n.countryInfoPick,
                                style: const TextStyle(
                                  color: AmaterasuColors.textSecondary,
                                ),
                              )
                            else
                              TripCountryInfoEntries(
                                key: ValueKey(country.code),
                                book: book,
                                country: country,
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
