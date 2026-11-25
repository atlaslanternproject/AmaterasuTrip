// Pannello "Orari e prezzi" di un ristorante, aperto solo su richiesta:
// orari della settimana e fascia di prezzo di Google (stessa richiesta dei
// contatti, in cache per la sessione, mai salvati), prezzo convertito nella
// valuta del viaggio e avviso se il giorno o l'ora prenotati sono chiusi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_providers.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_sheet.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/providers/trip_restaurants_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_restaurant_hours_parts.dart';

Future<void> showTripRestaurantHours(
  BuildContext context,
  TripRestaurant item,
  String tripCurrency,
) => showAmaterasuSheet<void>(
  context,
  builder: (_) => _HoursSheet(item: item, tripCurrency: tripCurrency),
);

class _HoursSheet extends ConsumerStatefulWidget {
  const _HoursSheet({required this.item, required this.tripCurrency});

  final TripRestaurant item;
  final String tripCurrency;

  @override
  ConsumerState<_HoursSheet> createState() => _HoursSheetState();
}

class _HoursSheetState extends ConsumerState<_HoursSheet> {
  late final Future<AmaterasuPlaceContacts?> _info = ref
      .read(amaterasuPlaceInfoProvider)
      .contacts(
        widget.item.place.placeId!,
        languageCode: Localizations.localeOf(context).languageCode,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      key: Key('restaurant-hours-sheet-${widget.item.id}'),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: FutureBuilder(
        future: _info,
        builder: (context, snap) {
          final info = snap.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.restaurantHours,
                style: const TextStyle(
                  color: AmaterasuColors.textCream,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (snap.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (snap.hasError)
                Text(l10n.restaurantHoursError)
              else ...[
                ...tripRestaurantClosedWarning(
                  context,
                  widget.item,
                  info?.hours,
                ),
                if (info == null || info.hours.weekdayText.isEmpty)
                  Text(l10n.restaurantHoursNone)
                else
                  for (final line in info.hours.weekdayText)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: AmaterasuColors.textPrimary,
                        ),
                      ),
                    ),
                if (info?.priceRange case final range?) ...[
                  const SizedBox(height: 12),
                  TripRestaurantGooglePrice(
                    range: range,
                    tripCurrency: widget.tripCurrency,
                    fx: ref.read(tripRestaurantFxProvider),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  l10n.restaurantHoursSource,
                  style: const TextStyle(
                    color: AmaterasuColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
