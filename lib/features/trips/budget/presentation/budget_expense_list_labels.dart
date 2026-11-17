// Parte di budget_expense_list.dart: etichette e icone
// di categoria e stato.

part of 'budget_expense_list.dart';

extension _BudgetExpenseListLabels on BudgetExpenseList {
  String _categoryLabel(String value, bool it) {
    switch (value) {
      case 'accommodation':
        return budgetL10n(it).btCatAccommodation;
      case 'food':
        return budgetL10n(it).btCatFoodDrinks;
      case 'transport':
        return budgetL10n(it).btCatTransport;
      case 'activities':
        return budgetL10n(it).btCatActivities;
      case 'shopping':
        return 'Shopping';
      case 'other':
        return budgetL10n(it).btCatOther;
      default:
        return value.trim().isEmpty ? (budgetL10n(it).btCatOther) : value;
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
        return budgetL10n(it).btListPaid;
      case 'planned':
        return budgetL10n(it).btStatusPlanned;
      case 'outstanding':
        return budgetL10n(it).btStatusOutstanding;
      default:
        return budgetL10n(it).btListStatusUnavailable;
    }
  }
}
