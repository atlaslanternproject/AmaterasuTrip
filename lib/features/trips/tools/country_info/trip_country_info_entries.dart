// Voci di "Info paese": ogni voce mostra il valore con fonte, licenza e
// data del file (numeri di emergenza con il loro significato); le voci senza dati non compaiono. Sotto, le schede
// ufficiali (Viaggiare Sicuri, consolati, Wikidata) per tutto il resto.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/core/links/amaterasu_link_chip.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_country_info_data.dart';

/// Viaggiare Sicuri country page: the site opens "Codice-3" (ISO alpha-3).
String tripCountryViaggiareSicuri(String iso3) =>
    'https://www.viaggiaresicuri.it/find-country/country/$iso3';

/// "110 polizia", one number per line; the bare number when its use is
/// not known.
String tripCountryEmergencyText(AppLocalizations l10n, TripCountryInfo c) {
  String use(String code) => switch (code) {
    'police' => l10n.countryInfoUsePolice,
    'fire' => l10n.countryInfoUseFire,
    'ambulance' => l10n.countryInfoUseAmbulance,
    'general' => l10n.countryInfoUseGeneral,
    'coastGuard' => l10n.countryInfoUseCoastGuard,
    'deaf' => l10n.countryInfoUseDeaf,
    _ => code,
  };
  return [
    for (final n in c.emergency)
      switch (c.emergencyUses[n]) {
        final uses? when uses.isNotEmpty => '$n · ${uses.map(use).join(', ')}',
        _ => n,
      },
  ].join('\n');
}

const tripCountryConsulateLink =
    'https://serviziconsolari.esteri.it/home/cerca-consolato';

class TripCountryInfoEntries extends StatelessWidget {
  const TripCountryInfoEntries({
    super.key,
    required this.book,
    required this.country,
  });

  final TripCountryInfoBook book;
  final TripCountryInfo country;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = country;
    final date = book.generated == null
        ? '-'
        : AmaterasuDates.day(context, book.generated!);
    final source = l10n.countryInfoSource(book.source, book.licence, date);
    final plugs = c.plugs.where((p) => p.length == 1).toList();
    final standards = c.plugs.where((p) => p.length > 1).toList();
    final entries = <(String, IconData, String, String)>[
      if (c.callingCode.isNotEmpty)
        (
          'calling',
          Icons.call_outlined,
          l10n.countryInfoCallingCode,
          c.callingCode.join(', '),
        ),
      if (c.emergency.isNotEmpty)
        (
          'emergency',
          Icons.emergency_outlined,
          l10n.countryInfoEmergency,
          tripCountryEmergencyText(l10n, c),
        ),
      if (c.plugs.isNotEmpty)
        (
          'plugs',
          Icons.power_outlined,
          l10n.countryInfoPlugs,
          [
            if (plugs.isNotEmpty) l10n.countryInfoPlugType(plugs.join(', ')),
            ...standards,
          ].join(' · '),
        ),
      if (c.voltage.isNotEmpty)
        (
          'voltage',
          Icons.bolt_outlined,
          l10n.countryInfoVoltage,
          c.voltage.map((v) => '$v V').join(', '),
        ),
      if (c.driving != null)
        (
          'driving',
          Icons.directions_car_outlined,
          l10n.countryInfoDriving,
          c.driving == 'left'
              ? l10n.countryInfoDrivingLeft
              : l10n.countryInfoDrivingRight,
        ),
      if (c.timeZones.isNotEmpty)
        (
          'zones',
          Icons.schedule_outlined,
          l10n.countryInfoTimeZones,
          c.timeZones.join(', '),
        ),
    ];
    return Column(
      children: [
        if (entries.isNotEmpty)
          TripSectionBlock(
            title: l10n.countryInfoPractical,
            icon: Icons.info_outline,
            children: [
              for (final (id, icon, title, value) in entries)
                _Entry(
                  key: Key('country-info-$id'),
                  icon: icon,
                  title: title,
                  value: value,
                  source: source,
                ),
            ],
          ),
        TripSectionBlock(
          title: l10n.countryInfoOfficial,
          icon: Icons.verified_outlined,
          children: [
            Text(
              l10n.countryInfoOfficialBody,
              style: const TextStyle(color: AmaterasuColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (c.iso3 != null)
                  AmaterasuLinkChip(
                    key: const Key('country-info-vs'),
                    link: tripCountryViaggiareSicuri(c.iso3!),
                    label: l10n.countryInfoViaggiareSicuri,
                  ),
                AmaterasuLinkChip(
                  key: const Key('country-info-consulate'),
                  link: tripCountryConsulateLink,
                  label: l10n.countryInfoConsulate,
                ),
                if (c.wikidata != null)
                  AmaterasuLinkChip(
                    key: const Key('country-info-wikidata'),
                    link: 'https://www.wikidata.org/wiki/${c.wikidata}',
                    label: l10n.countryInfoWikidata,
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.source,
  });

  final IconData icon;
  final String title, value, source;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AmaterasuColors.accentGold, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AmaterasuColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AmaterasuColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                source,
                style: const TextStyle(
                  color: AmaterasuColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
