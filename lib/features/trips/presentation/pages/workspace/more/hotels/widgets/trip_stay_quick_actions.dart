// Azioni rapide di un soggiorno come icone con suggerimento (viste Elenco
// e Dettagli): Mappa, Spesa, Contatta (solo se c'è un contatto), Modifica
// e il menu con Elimina per chi può eliminare.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_contact_dialog.dart';

class TripStayQuickActions extends StatelessWidget {
  const TripStayQuickActions({
    super.key,
    required this.stay,
    this.expense,
    this.onEdit,
    this.menu,
    this.launch,
  });

  static const iconSize = 20.0;

  final TripStay stay;

  /// Expense icon (create / link / view), where the expense is shown today.
  final Widget? expense;
  final VoidCallback? onEdit;

  /// "⋮" menu with Elimina, only for who may delete.
  final Widget? menu;
  final AmaterasuLaunch? launch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maps = AmaterasuWebLink.googleMaps(
      name: stay.name,
      placeId: stay.googlePlaceId,
      latitude: stay.latitude,
      longitude: stay.longitude,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (maps != null)
          TripStayQuickButton(
            key: Key('stay-quick-map-${stay.id}'),
            icon: Icons.map_outlined,
            tooltip: l10n.staysOpenMap,
            onPressed: () => AmaterasuLinkOpener.openMaps(
              context,
              maps,
              failedMessage: l10n.commonMapsOpenFailed,
              launch: launch ?? AmaterasuLinkOpener.defaultLaunch,
            ),
          ),
        ?expense,
        if (tripStayHasContacts(stay))
          TripStayQuickButton(
            key: Key('stay-quick-contact-${stay.id}'),
            icon: Icons.contact_phone_outlined,
            tooltip: l10n.staysContact,
            onPressed: () =>
                showTripStayContactDialog(context, stay, launch: launch),
          ),
        if (onEdit != null)
          TripStayQuickButton(
            key: Key('stay-quick-edit-${stay.id}'),
            icon: Icons.edit_outlined,
            tooltip: l10n.staysEdit,
            onPressed: onEdit,
          ),
        ?menu,
      ],
    );
  }
}

/// Small icon button with a tooltip, sized for the compact views.
class TripStayQuickButton extends StatelessWidget {
  const TripStayQuickButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    iconSize: TripStayQuickActions.iconSize,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    color: AmaterasuColors.accentGold,
    disabledColor: AmaterasuColors.textMuted,
    icon: Icon(icon),
  );
}
