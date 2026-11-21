// Link nella card di un soggiorno: prenotazione e sito dell'alloggio con
// AmaterasuLinkChip, e pulsante mappa (Google Maps) con AmaterasuLinkOpener.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_chip.dart';
import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripStayCardLinks extends StatelessWidget {
  const TripStayCardLinks({super.key, required this.stay, this.launch});

  final TripStay stay;

  /// Replaces url_launcher in tests.
  final AmaterasuLaunch? launch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final booking = stay.bookingUrl;
    final property = stay.propertyUrl;
    final maps = AmaterasuWebLink.googleMaps(
      name: stay.name,
      placeId: stay.googlePlaceId,
      latitude: stay.latitude,
      longitude: stay.longitude,
    );
    if (booking == null && property == null && maps == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: AmaterasuSpacing.sm,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (booking != null)
            AmaterasuLinkChip(
              key: const Key('stay-link-booking'),
              link: booking,
              label: l10n.staysLinkBooking,
              launch: launch,
            ),
          if (property != null)
            AmaterasuLinkChip(
              key: const Key('stay-link-property'),
              link: property,
              label: l10n.staysLinkProperty,
              launch: launch,
            ),
          if (maps != null)
            TextButton.icon(
              key: const Key('stay-map'),
              style: TextButton.styleFrom(
                foregroundColor: AmaterasuColors.accentBudget,
              ),
              onPressed: () => AmaterasuLinkOpener.openMaps(
                context,
                maps,
                failedMessage: l10n.commonMapsOpenFailed,
                launch: launch ?? AmaterasuLinkOpener.defaultLaunch,
              ),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(l10n.staysOpenMap),
            ),
        ],
      ),
    );
  }
}
