import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'budget_api.dart';
import 'budget_expense_filters.dart';
import 'budget_expense_details_dialog.dart';
import 'budget_display_amount.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';

class BudgetExpenseList extends StatelessWidget {
  const BudgetExpenseList({
    super.key,
    required this.api,
    required this.private,
    required this.filters,
    required this.displayCurrency,
    this.categoryNames = const {},
  });

  final BudgetApi api;
  final bool private;
  final BudgetExpenseFilters filters;
  final String displayCurrency;
  final Map<String, String> categoryNames;

  static const _cream = AmaterasuColors.textPrimary;
  static const _muted = AmaterasuColors.textSecondary;
  static const _gold = AmaterasuColors.accentGold;

  String _categoryLabel(String value, bool it) {
    switch (value) {
      case 'accommodation':
        return _l10n(it).btCatAccommodation;
      case 'food':
        return _l10n(it).btCatFoodDrinks;
      case 'transport':
        return _l10n(it).btCatTransport;
      case 'activities':
        return _l10n(it).btCatActivities;
      case 'shopping':
        return 'Shopping';
      case 'other':
        return _l10n(it).btCatOther;
      default:
        return value.trim().isEmpty ? (_l10n(it).btCatOther) : value;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'accommodation':
        return Icons.hotel_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'transport':
        return Icons.train_outlined;
      case 'activities':
        return Icons.local_activity_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  String _statusLabel(String status, bool it) {
    switch (status) {
      case 'paid':
        return _l10n(it).btListPaid;
      case 'planned':
        return _l10n(it).btStatusPlanned;
      case 'outstanding':
        return _l10n(it).btStatusOutstanding;
      default:
        return _l10n(it).btListStatusUnavailable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = Localizations.localeOf(context).languageCode == 'it';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: private ? api.privateExpenses() : api.sharedExpenses(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(AmaterasuSpacing.md),
            child: Text(
              _l10n(it).btUnableToLoadExpenses,
              style: const TextStyle(color: _muted),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(AmaterasuSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs
            .where((doc) => filters.matches(doc.data(), DateTime.now()))
            .toList();
        // B8.1.1: applicare un solo ordinamento, quello scelto.
        docs.sort((a, b) => filters.compare(a.data(), b.data()));

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 32,
                  color: _muted,
                ),
                const SizedBox(height: 10),
                Text(
                  _l10n(it).btListNoExpensesToDisplay,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            for (final doc in docs)
              Builder(
                builder: (context) {
                  final data = doc.data();

                  final raw = data['snapshot'];
                  if (raw is! Map) {
                    return const SizedBox.shrink();
                  }

                  final financial = Map<String, dynamic>.from(raw);
                  final rawTotal = financial['total'];
                  if (rawTotal is! Map) {
                    return const SizedBox.shrink();
                  }

                  final total = Map<String, dynamic>.from(rawTotal);
                  final units = total['minorUnits'] as int? ?? 0;
                  final currency = total['currency'] as String? ?? 'EUR';

                  final status = financial['status']?.toString() ?? '';

                  final category = data['category']?.toString() ?? 'other';

                  final rawTitle = (data['title']?.toString() ?? '').trim();

                  final title = rawTitle.isNotEmpty
                      ? rawTitle
                      : (_l10n(it).btUntitledExpense);

                  final notes = (data['notes']?.toString() ?? '').trim();

                  final shares = financial['shares'] is Map
                      ? Map<String, dynamic>.from(financial['shares'] as Map)
                      : <String, dynamic>{};

                  return Card(
                    color: const Color(0xFF211815),
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                      side: const BorderSide(color: Color(0xFF543429)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(17),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (dialogContext) => BudgetExpenseDetailsDialog(
                          expense: data,
                          expenseId: doc.id,
                          api: api,
                          isPrivate: private,
                          displayCurrency: displayCurrency,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AmaterasuSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 43,
                              height: 43,
                              decoration: BoxDecoration(
                                color: const Color(0xFF382820),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _categoryIcon(category),
                                color: _gold,
                                size: 23,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: _cream,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    categoryNames[category] ??
                                        _categoryLabel(category, it),
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 11),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 7,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      BudgetDisplayAmount(
                                        expense: data,
                                        minorUnits: units,
                                        originalCurrency: currency,
                                        displayCurrency: displayCurrency,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3A2C26),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          _statusLabel(status, it),
                                          style: const TextStyle(
                                            color: _cream,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      if (!private)
                                        Text(
                                          _l10n(
                                            it,
                                          ).btListTravelers(shares.length),
                                          style: const TextStyle(
                                            color: _muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (notes.isNotEmpty)
                                        const Tooltip(
                                          message: 'Note',
                                          child: Icon(
                                            Icons.notes_outlined,
                                            color: _muted,
                                            size: 17,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: _gold,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

/// Texts of this screen, in the language chosen by the existing `it` flag.
AppLocalizations _l10n(bool it) =>
    lookupAppLocalizations(Locale(it ? 'it' : 'en'));
