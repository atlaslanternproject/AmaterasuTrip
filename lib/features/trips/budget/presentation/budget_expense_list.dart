import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../calculations/currency_minor_units.dart';
import 'budget_api.dart';
import 'budget_expense_details_dialog.dart';

class BudgetExpenseList extends StatelessWidget {
  const BudgetExpenseList({
    super.key,
    required this.api,
    required this.private,
  });

  final BudgetApi api;
  final bool private;

  static const _cream = Color(0xFFF2E7D5);
  static const _muted = Color(0xFFB7A99B);
  static const _gold = Color(0xFFE3A66C);

  String _categoryLabel(String value, bool it) {
    switch (value) {
      case 'accommodation':
        return it ? 'Alloggio' : 'Accommodation';
      case 'food':
        return it ? 'Cibo e bevande' : 'Food & drinks';
      case 'transport':
        return it ? 'Trasporti' : 'Transport';
      case 'activities':
        return it ? 'Attività' : 'Activities';
      case 'shopping':
        return 'Shopping';
      case 'other':
        return it ? 'Altro' : 'Other';
      default:
        return value.trim().isEmpty ? (it ? 'Altro' : 'Other') : value;
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
        return it ? 'Saldata' : 'Paid';
      case 'planned':
        return it ? 'Prevista' : 'Planned';
      case 'outstanding':
        return it ? 'Da saldare' : 'Outstanding';
      default:
        return it ? 'Stato non disponibile' : 'Status unavailable';
    }
  }

  String _money(int minor, String currency) {
    int decimals;

    try {
      decimals = CurrencyMinorUnits.decimals(currency);
    } catch (_) {
      return '$minor $currency';
    }

    final factor = CurrencyMinorUnits.factor(currency);
    final negative = minor < 0 ? '-' : '';
    final absolute = minor.abs();
    final whole = absolute ~/ factor;

    if (decimals == 0) {
      return '$negative$whole $currency';
    }

    final fraction = (absolute % factor).toString().padLeft(decimals, '0');

    return '$negative$whole,$fraction $currency';
  }

  @override
  Widget build(BuildContext context) {
    final it = Localizations.localeOf(context).languageCode == 'it';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: private ? api.privateExpenses() : api.sharedExpenses(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              it
                  ? 'Impossibile caricare le spese.'
                  : 'Unable to load expenses.',
              style: const TextStyle(color: _muted),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs
            .where((doc) => doc.data()['lifecycle'] != 'cancelled')
            .toList();

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
                  it ? 'Nessuna spesa da mostrare.' : 'No expenses to display.',
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
                      : (it ? 'Spesa senza titolo' : 'Untitled expense');

                  final notes = (data['notes']?.toString() ?? '').trim();

                  final shares = financial['shares'] is Map
                      ? Map<String, dynamic>.from(financial['shares'] as Map)
                      : <String, dynamic>{};

                  return Card(
                    color: const Color(0xFF241A16),
                    margin: const EdgeInsets.symmetric(vertical: 7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
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
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                                      Text(
                                        _money(units, currency),
                                        style: const TextStyle(
                                          color: _gold,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
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
                                          it
                                              ? '${shares.length} partecipanti'
                                              : '${shares.length} travelers',
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
