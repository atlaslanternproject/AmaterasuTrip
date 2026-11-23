// Azioni rapide di un elemento come icone (viste Elenco e Dettagli, e
// riga in fondo alla card): Mappa, Spesa, Contatta (se c'è un contatto),
// Modifica e il menu con Elimina per chi può eliminare.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/places/widgets/amaterasu_contact_dialog.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_section_entry.dart';
import 'trip_section_quick_button.dart';

class TripSectionQuickActions extends StatelessWidget {
  const TripSectionQuickActions({
    super.key,
    required this.keyPrefix,
    required this.entry,
    this.expense,
    this.onEdit,
    this.menu,
    this.launch,
  });

  final String keyPrefix;
  final TripSectionEntry entry;
  final Widget? expense;
  final VoidCallback? onEdit;
  final Widget? menu;
  final AmaterasuLaunch? launch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maps = entry.maps;
    final id = entry.id;
    final hasContacts = amaterasuHasContacts(
      phone: entry.phone,
      email: entry.email,
      website: entry.website,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (maps != null)
          TripSectionQuickButton(
            key: Key('$keyPrefix-quick-map-$id'),
            icon: Icons.map_outlined,
            tooltip: l10n.sectionsOpenMap,
            onPressed: () => AmaterasuLinkOpener.openMaps(
              context,
              maps,
              failedMessage: l10n.commonMapsOpenFailed,
              launch: launch ?? AmaterasuLinkOpener.defaultLaunch,
            ),
          ),
        ?expense,
        if (hasContacts)
          TripSectionQuickButton(
            key: Key('$keyPrefix-quick-contact-$id'),
            icon: Icons.contact_phone_outlined,
            tooltip: l10n.sectionsContact,
            onPressed: () => showAmaterasuContactDialog(
              context,
              title: l10n.sectionsContactTitle(entry.title),
              phone: entry.phone,
              email: entry.email,
              website: entry.website,
              launch: launch,
              keyPrefix: '$keyPrefix-contact',
            ),
          ),
        if (onEdit != null)
          TripSectionQuickButton(
            key: Key('$keyPrefix-quick-edit-$id'),
            icon: Icons.edit_outlined,
            tooltip: l10n.sectionsEdit,
            onPressed: onEdit,
          ),
        ?menu,
      ],
    );
  }
}
