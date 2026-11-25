// Pannello "Orari e prezzi" di un luogo Google delle sezioni (ristoranti,
// luoghi salvati), aperto solo su richiesta: orari della settimana e fascia
// di prezzo di Google (stessa richiesta dei contatti, in cache per la
// sessione, mai salvati), prezzo convertito nella valuta del viaggio e
// avviso se il giorno o l'ora previsti risultano chiusi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_providers.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_sheet.dart';
import 'package:amaterasutrip/features/trips/budget/data/budget_fx_service.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_section_hours_parts.dart';

/// Exchange rates for the Google price, read only when the user opens
/// "Hours and prices" (same free service and cache as the budget).
final tripSectionFxProvider = Provider<BudgetFxService>(
  (ref) => BudgetFxService(),
);

/// What the sheet needs: the place and the planned day and time, if any.
class TripSectionHoursTarget {
  const TripSectionHoursTarget({
    required this.keyPrefix,
    required this.id,
    required this.placeId,
    required this.tripCurrency,
    this.day,
    this.time,
  });

  final String keyPrefix;
  final String id;
  final String placeId;
  final String tripCurrency;
  final DateTime? day;
  final String? time;
}

Future<void> showTripSectionHours(
  BuildContext context,
  TripSectionHoursTarget target,
) => showAmaterasuSheet<void>(
  context,
  builder: (_) => _HoursSheet(target: target),
);

class _HoursSheet extends ConsumerStatefulWidget {
  const _HoursSheet({required this.target});

  final TripSectionHoursTarget target;

  @override
  ConsumerState<_HoursSheet> createState() => _HoursSheetState();
}

class _HoursSheetState extends ConsumerState<_HoursSheet> {
  late final Future<AmaterasuPlaceContacts?> _info = ref
      .read(amaterasuPlaceInfoProvider)
      .contacts(
        widget.target.placeId,
        languageCode: Localizations.localeOf(context).languageCode,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = widget.target;
    return SingleChildScrollView(
      key: Key('${t.keyPrefix}-hours-sheet-${t.id}'),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: FutureBuilder(
        future: _info,
        builder: (context, snap) {
          final info = snap.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.sectionsHours,
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
                Text(l10n.sectionsHoursError)
              else ...[
                ...tripSectionClosedWarning(context, t, info?.hours),
                if (info == null || info.hours.weekdayText.isEmpty)
                  Text(l10n.sectionsHoursNone)
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
                  TripSectionGooglePrice(
                    range: range,
                    tripCurrency: t.tripCurrency,
                    fx: ref.read(tripSectionFxProvider),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  l10n.sectionsHoursSource,
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

/// "Hours and prices" button of a card; nothing is asked to Google until
/// it is pressed.
class TripSectionHoursButton extends StatelessWidget {
  const TripSectionHoursButton({super.key, required this.target});

  final TripSectionHoursTarget target;

  @override
  Widget build(BuildContext context) => AmaterasuButton.tertiary(
    key: Key('${target.keyPrefix}-hours-${target.id}'),
    icon: Icons.schedule_rounded,
    label: AppLocalizations.of(context)!.sectionsHours,
    onPressed: () => showTripSectionHours(context, target),
  );
}
