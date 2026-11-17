// Pagina "Altro" del workspace: accesso alle sezioni secondarie del viaggio.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/core/theme/amaterasu_radius.dart';

class TripMorePage extends StatelessWidget {
  const TripMorePage({super.key, required this.tripId});

  final String tripId;

  static const Color _backgroundColor = AmaterasuColors.surfaceDeep;
  static const Color _surfaceColor = AmaterasuColors.surfaceWarm;
  static const Color _borderColor = AmaterasuColors.borderAccent;
  static const Color _accentColor = AmaterasuColors.accentBudget;
  static const Color _titleColor = AmaterasuColors.textPrimary;
  static const Color _secondaryTextColor = AmaterasuColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final items = [
      _TripMoreItem(
        title: l10n.tripMapTitle,
        subtitle: l10n.tripMapSubtitle,
        icon: Icons.map_outlined,
        route: '/trips/$tripId/more/map',
      ),
      _TripMoreItem(
        title: l10n.tripExpensesTitle,
        subtitle: l10n.tripExpensesSubtitle,
        icon: Icons.receipt_long_outlined,
        route: '/trips/$tripId/more/expenses',
      ),
      _TripMoreItem(
        title: l10n.tripTravellersTitle,
        subtitle: l10n.tripTravellersSubtitle,
        icon: Icons.group_outlined,
        route: '/trips/$tripId/more/travellers',
      ),
      _TripMoreItem(
        title: l10n.tripMoreRestaurants,
        subtitle: l10n.tripMoreRestaurantsSubtitle,
        icon: Icons.restaurant_rounded,
        route: '/trips/$tripId/more/restaurants',
      ),
      _TripMoreItem(
        title: l10n.tripMoreHotels,
        subtitle: l10n.tripMoreHotelsSubtitle,
        icon: Icons.hotel_rounded,
        route: '/trips/$tripId/more/hotels',
      ),
      _TripMoreItem(
        title: l10n.tripMoreShopping,
        subtitle: l10n.tripMoreShoppingSubtitle,
        icon: Icons.shopping_bag_rounded,
        route: '/trips/$tripId/more/shopping',
      ),
      _TripMoreItem(
        title: l10n.tripMoreTransport,
        subtitle: l10n.tripMoreTransportSubtitle,
        icon: Icons.train_rounded,
        route: '/trips/$tripId/more/transport',
      ),
      _TripMoreItem(
        title: l10n.tripMoreBookings,
        subtitle: l10n.tripMoreBookingsSubtitle,
        icon: Icons.confirmation_number_rounded,
        route: '/trips/$tripId/more/bookings',
      ),
      _TripMoreItem(
        title: l10n.tripMoreSavedPlaces,
        subtitle: l10n.tripMoreSavedPlacesSubtitle,
        icon: Icons.bookmark_rounded,
        route: '/trips/$tripId/more/saved-places',
      ),
      _TripMoreItem(
        title: l10n.tripMoreMemories,
        subtitle: l10n.tripMoreMemoriesSubtitle,
        icon: Icons.photo_library_rounded,
        route: '/trips/$tripId/more/memories',
      ),
      _TripMoreItem(
        title: l10n.tripMoreNotes,
        subtitle: l10n.tripMoreNotesSubtitle,
        icon: Icons.notes_rounded,
        route: '/trips/$tripId/more/notes',
      ),
      _TripMoreItem(
        title: l10n.tripMoreSettings,
        subtitle: l10n.tripMoreSettingsSubtitle,
        icon: Icons.settings_rounded,
        route: '/trips/$tripId/settings',
      ),
    ];

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/trips/$tripId'),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(width: AmaterasuSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tripMoreTitle,
                          style: const TextStyle(
                            color: _titleColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.tripMoreSubtitle,
                          style: const TextStyle(
                            color: _secondaryTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];

                  return _MoreCard(
                    item: item,
                    onTap: () => context.go(item.route),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreCard extends StatelessWidget {
  const _MoreCard({required this.item, required this.onTap});

  final _TripMoreItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TripMorePage._surfaceColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(AmaterasuSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: TripMorePage._borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: TripMorePage._accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AmaterasuRadius.md),
                ),
                child: Icon(
                  item.icon,
                  color: TripMorePage._accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: TripMorePage._titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: TripMorePage._secondaryTextColor,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: TripMorePage._secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripMoreItem {
  const _TripMoreItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
