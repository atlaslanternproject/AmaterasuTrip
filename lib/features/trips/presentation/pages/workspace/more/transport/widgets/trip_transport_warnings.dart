// Avviso solo informativo dei trasporti: coincidenze sotto l'ora e arrivi
// dopo la partenza del trasporto successivo (tutti i trasporti attivi,
// non solo quelli filtrati).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_notice.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_timeline.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_transport_labels.dart';

class TripTransportWarnings extends StatelessWidget {
  const TripTransportWarnings({super.key, required this.items});

  final List<TripTransport> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String name(TripTransport t) => TripTransportLabels.title(t, l10n);
    return TripSectionNotice(
      key: const Key('transport-warnings'),
      icon: Icons.warning_amber_rounded,
      hint: l10n.transportWarningHint,
      lines: [
        for (final w in TripTransportTimeline.warnings(items))
          w.overlaps
              ? l10n.transportWarningOverlap(name(w.first), name(w.second))
              : l10n.transportWarningTight(
                  w.minutes,
                  name(w.first),
                  name(w.second),
                ),
      ],
    );
  }
}
