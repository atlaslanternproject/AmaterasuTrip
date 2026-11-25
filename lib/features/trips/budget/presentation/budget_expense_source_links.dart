// Riquadro del dettaglio di una spesa con la sezione che l'ha generata
// ("Vai al trasporto / all'hotel / ...") e il link facoltativo. Compare
// solo quando la spesa ha questi dati; non tocca importi né calcoli.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_chip.dart';
import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'budget_dialog_chrome.dart';

class BudgetExpenseSourceLinks extends StatelessWidget {
  const BudgetExpenseSourceLinks({
    super.key,
    required this.tripId,
    required this.expense,
  });

  final String tripId;
  final Map<String, dynamic> expense;

  /// Page of the trip workspace for each section.
  static const _pages = {
    'stays': 'hotels',
    'transports': 'transport',
    'reservations': 'bookings',
    'restaurants': 'restaurants',
    'shoppingItems': 'shopping',
  };

  String _label(String section, AppLocalizations l10n) => switch (section) {
    'stays' => l10n.btGoToStay,
    'transports' => l10n.btGoToTransport,
    'reservations' => l10n.btGoToReservation,
    'restaurants' => l10n.btGoToRestaurant,
    _ => l10n.btGoToShopping,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final raw = expense['source'];
    final section = raw is Map ? raw['section'] : null;
    final page = _pages[section];
    final link = expense['link'];
    final hasLink = link is String && AmaterasuWebLink.isValid(link);
    if (page == null && !hasLink) return const SizedBox.shrink();
    return BudgetDialogChrome.section(
      title: l10n.btDetailsSourceLinks,
      icon: Icons.link_rounded,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (page != null)
              ActionChip(
                key: const Key('budget-expense-source'),
                avatar: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(_label(section as String, l10n)),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/trips/$tripId/more/$page');
                },
              ),
            if (hasLink) AmaterasuLinkChip(link: link),
          ],
        ),
      ],
    );
  }
}
